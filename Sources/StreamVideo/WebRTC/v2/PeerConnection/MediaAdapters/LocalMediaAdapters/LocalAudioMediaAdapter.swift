//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class responsible for managing local audio media during a call session.
///
/// `LocalAudioMediaAdapter` handles the configuration, publishing, and
/// updating of local audio tracks within a WebRTC session. It integrates
/// with WebRTC components and supports features like muting, quality updates,
/// and SFU communication.
final class LocalAudioMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    /// The audio recorder for capturing audio during the call session.
    @Injected(\.callAudioRecorder) private var audioRecorder

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection used for managing media streams.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// A factory for creating WebRTC components, such as tracks and sources.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The adapter for interacting with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    /// The options for publishing audio tracks.
    private var publishOptions: [PublishOptions.AudioPublishOptions]

    /// The identifiers for the streams associated with this audio adapter.
    private let streamIds: [String]

    /// A storage for managing audio transceivers.
    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.AudioPublishOptions>(for: .audio)

    /// The last applied audio call settings.
    private var lastUpdatedCallSettings: CallSettings.Audio?

    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    /// The session's local microphone track.
    ///
    /// Clones of this track are attached to audio senders (Opus, RED,
    /// and any extra negotiated codec). The underlying `RTCAudioSource`
    /// is immutable, so this property is replaced when the capture
    /// profile crosses music: unmute `SetAudioSend` then reads the new
    /// source options (software NS/HPF off) instead of the voice
    /// defaults.
    private(set) var primaryTrack: RTCAudioTrack

    /// A publisher that emits events related to audio tracks.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Shared box used to attach an encryptor after `addTransceiver`.
    private let e2ee: E2EEAttachmentContext

    private var hasRegisteredPrimaryTrack: Bool = false
    private var ownCapabilities: [OwnCapability] = []
    private var audioBitrateProfile: AudioBitrateProfile = .voiceStandard
    private var restoredBitrates: [PublishOptions.AudioPublishOptions: Int] = [:]

    /// Initializes a new instance of `LocalAudioMediaAdapter`.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - publishOptions: The options for publishing audio tracks.
    ///   - subject: A publisher that emits track events.
    ///   - e2ee: Shared box used to encrypt the local audio sender.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.AudioPublishOptions],
        subject: PassthroughSubject<TrackEvent, Never>,
        e2ee: E2EEAttachmentContext = .init()
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.publishOptions = publishOptions
        self.subject = subject
        self.e2ee = e2ee

        // Create the primary audio track for the session.
        let source = peerConnectionFactory.makeAudioSource(
            .audioCaptureConstraints(for: .voiceStandard)
        )
        let track = peerConnectionFactory.makeAudioTrack(source: source)
        primaryTrack = track
        streamIds = ["\(sessionID):audio"]

        // Disable the primary track by default.
        track.isEnabled = false
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        transceiverStorage.removeAll()
        log.debug(
            """
            Local audio tracks will be deallocated:
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )
    }

    // MARK: - LocalMediaManaging

    /// Configures the local audio media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The settings for the call, such as whether audio is enabled.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        self.ownCapabilities = ownCapabilities
        guard ownCapabilities.contains(.sendAudio), settings.audioOn else {
            return
        }

        // Notify that the primary audio track has been added.
        registerPrimaryTrackIfPossible(settings)
    }

    /// Starts publishing the local audio track.
    ///
    /// This enables the primary track and creates additional transceivers based
    /// on the current publish options. It also starts the audio recorder.
    ///
    /// This method is intended to be triggered by local adapter flow (for example,
    /// through call settings updates) and not called directly by external
    /// consumers.
    func publish() async throws {
        guard
            !primaryTrack.isEnabled
        else {
            return
        }

        primaryTrack.isEnabled = true
        do {
            for options in publishOptions {
                try addTransceiverIfRequired(
                    for: options,
                    with: primaryTrack.clone(from: peerConnectionFactory)
                )
            }

            let activePublishOptions = Set(self.publishOptions)
            transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }

            audioRecorder.startRecording()

            log.debug(
                """
                Local audio tracks are now published:
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        } catch {
            primaryTrack.isEnabled = false
            throw error
        }
    }

    /// Stops publishing the local audio track.
    ///
    /// This disables the primary track and all associated transceivers.
    ///
    /// This method is intended to be triggered by local adapter flow (for example,
    /// through call settings updates) and not called directly by external
    /// consumers.
    func unpublish() async throws {
        guard primaryTrack.isEnabled else { return }

        primaryTrack.isEnabled = false

        transceiverStorage
            .forEach { $0.value.track.isEnabled = false }

        audioRecorder.stopRecording()

        log.debug(
            """
            Local audio tracks are now unpublished:
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )
    }

    /// Updates the local audio media based on new call settings.
    ///
    /// - Parameter settings: The updated settings for the call.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, ownCapabilities.contains(.sendAudio) else { return }
            registerPrimaryTrackIfPossible(settings)

            guard lastUpdatedCallSettings != settings.audio else { return }

            let isMuted = !settings.audioOn
            let isLocalMuted = !primaryTrack.isEnabled

            if isMuted != isLocalMuted {
                try await sfuAdapter.updateTrackMuteState(
                    .audio,
                    isMuted: isMuted,
                    for: sessionID
                )
            }

            if isMuted, primaryTrack.isEnabled {
                try await unpublish()
            } else if !isMuted {
                try await publish()
            }

            lastUpdatedCallSettings = settings.audio
        }
    }

    /// Updates cached local participant capabilities used by subsequent setting updates.
    ///
    /// The adapter uses this for media operations that depend on whether audio
    /// publishing is currently permitted for the participant.
    func didUpdateOwnCapabilities(
        _ ownCapabilities: Set<OwnCapability>
    ) {
        processingQueue.addOperation { [weak self] in
            self?.ownCapabilities = Array(ownCapabilities)
        }
    }

    /// Updates the publish options for the local audio track.
    ///
    /// - Parameter publishOptions: The new publish options.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else { return }

            self.publishOptions = publishOptions.audio

            guard primaryTrack.isEnabled else { return }

            for option in self.publishOptions {
                try addTransceiverIfRequired(
                    for: option,
                    with: primaryTrack.clone(from: peerConnectionFactory)
                )
            }

            let activePublishOptions = Set(self.publishOptions)

            transceiverStorage
                .forEach {
                    if activePublishOptions.contains($0.key) {
                        $0.value.track.isEnabled = true
                        $0.value.transceiver.sender.track = $0.value.track
                    } else {
                        $0.value.track.isEnabled = false
                        $0.value.transceiver.sender.track = nil
                    }
                }
            applyCurrentProfileBitrate()

            log.debug(
                """
                Local audio tracks updated:
                    PublishOptions: \(self.publishOptions)
                    TransceiverStorage: \(transceiverStorage)
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Returns track information for the local audio tracks.
    ///
    /// - Returns: An array of `Stream_Video_Sfu_Models_TrackInfo` representing
    ///   the local audio tracks.
    func trackInfo(
        for collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        let transceivers = {
            switch collectionType {
            case .allAvailable:
                return transceiverStorage
                    .map { ($0, $1.transceiver, $1.track) }
            case .lastPublishOptions:
                return publishOptions
                    .compactMap {
                        if
                            let entry = transceiverStorage.get(for: $0),
                            entry.transceiver.sender.track != nil {
                            return ($0, entry.transceiver, entry.track)
                        } else {
                            return nil
                        }
                    }
            }
        }()

        return transceivers
            .map { publishOptions, transceiver, track in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .audio
                trackInfo.trackID = track.trackId
                trackInfo.mid = transceiver.mid
                trackInfo.muted = !track.isEnabled
                trackInfo.codec = .init(publishOptions.codec)
                return trackInfo
            }
    }

    /// Updates the publishing quality of the audio track.
    ///
    /// - Parameter layerSettings: An array of `Stream_Video_Sfu_Event_AudioSender`
    ///   objects representing the quality settings for the audio layers.
    ///
    /// This method is intended to apply quality adjustments to the audio track,
    /// but the current implementation is a no-op. Override or extend this method
    /// to provide custom logic for changing the audio track's publish quality.
    ///
    /// - Note: If quality adjustments are not required, this no-op implementation
    ///   can be left unchanged.
    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_AudioSender]
    ) { /* No-op */ }

    /// Applies the profile's Opus bitrate and, if the profile crossed
    /// music, rebuilds the capture source.
    ///
    /// Bitrate is written on existing sender encodings and does not
    /// renegotiate. Crossing music replaces ``primaryTrack`` and every
    /// stored sender track so later mute/unmute publish uses music APM
    /// flags. Same-side voice profiles (standard ↔ high quality) only
    /// change bitrate.
    ///
    /// - Parameter profile: The profile to stamp on senders and, when
    ///   `isMusic` changes, on a new `RTCAudioSource`.
    func setMaxBitrate(for profile: AudioBitrateProfile) async {
        try? await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else { return }
            let previous = audioBitrateProfile
            audioBitrateProfile = profile
            applyCurrentProfileBitrate()
            rebuildAudioSourceIfNeeded(from: previous, to: profile)
            if profile == .voiceStandard {
                restoredBitrates.removeAll()
            }
        }
    }

    // MARK: - Private Helpers

    /// Adds or updates a transceiver for a given audio track and publish option.
    ///
    /// When E2EE is enabled, the encryptor is attached before the transceiver
    /// is stored. Attach failure clears the sender track and throws so
    /// the track is not announced.
    ///
    /// - Parameters:
    ///   - options: The options for publishing the audio track.
    ///   - track: The audio track to be added or updated.
    private func addTransceiverIfRequired(
        for options: PublishOptions.AudioPublishOptions,
        with track: RTCAudioTrack
    ) throws {
        guard !transceiverStorage.contains(key: options) else {
            return
        }

        guard
            let transceiver = peerConnection.addTransceiver(
                trackType: .audio,
                with: track,
                init: .init(
                    direction: .sendOnly,
                    streamIds: streamIds,
                    audioOptions: options
                )
            )
        else {
            log.warning("Unable to create transceiver for options:\(options).", subsystems: .webRTC)
            return
        }
        applyProfileBitrate(for: options, on: transceiver)
        try e2ee.encryptIfNeeded(
            sender: transceiver.sender,
            codec: options.codec.e2eeCodecPin,
            trackType: .audio
        )
        transceiverStorage.set(transceiver, track: track, for: options)
    }

    /// Rebuilds the capture source when `previous.isMusic` differs from
    /// `profile.isMusic`.
    ///
    /// WebRTC `LocalAudioSource` copies goog* flags at create and
    /// exposes no setter. Unmute enables the track, which runs
    /// `SetAudioSend` → `SetOptions` from those copied flags. A voice
    /// source therefore restored software NS/HPF while Apple Voice
    /// Processing was still off, which chopped or delayed published
    /// audio.
    ///
    /// Creates one new source and track, then swaps a clone onto every
    /// stored audio transceiver (Opus, RED, inactive codecs).
    /// `RtpSender.SetTrack` does not mark negotiation needed, so mids
    /// stay. Detached senders only update storage so the next attach
    /// uses the matching source.
    ///
    /// Mirrors JS web re-gUM with music constraints. Mute still
    /// unpublishes, matching JS `stopPublish` and Android disable.
    private func rebuildAudioSourceIfNeeded(
        from previous: AudioBitrateProfile,
        to profile: AudioBitrateProfile
    ) {
        guard previous.isMusic != profile.isMusic else { return }

        let source = peerConnectionFactory.makeAudioSource(
            .audioCaptureConstraints(for: profile)
        )
        let track = peerConnectionFactory.makeAudioTrack(source: source)
        track.isEnabled = primaryTrack.isEnabled
        let previousTrack = primaryTrack
        primaryTrack = track

        transceiverStorage.forEach { options, value in
            let clone = track.clone(from: peerConnectionFactory)
            clone.isEnabled = value.track.isEnabled
            let wasAttached = value.transceiver.sender.track != nil
            transceiverStorage.set(
                value.transceiver,
                track: clone,
                for: options
            )
            if wasAttached {
                value.transceiver.sender.track = clone
            }
        }

        log.debug(
            """
            Local audio source rebuilt for profile:\(profile)
                previous: \(previousTrack.trackId) isEnabled:\(previousTrack.isEnabled)
                primary: \(track.trackId) isEnabled:\(track.isEnabled)
                clones: \(transceiverStorage.map(\.value.track.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )

        guard hasRegisteredPrimaryTrack else { return }
        subject.send(
            .removed(
                id: sessionID,
                trackType: .audio,
                track: previousTrack
            )
        )
        subject.send(
            .added(
                id: sessionID,
                trackType: .audio,
                track: track
            )
        )
    }

    /// Uses live `publishOptions`, not the storage key. Equality is only
    /// id+codec, so an SFU profile-map refresh would otherwise keep the
    /// stale bitrate.
    private func applyCurrentProfileBitrate() {
        transceiverStorage.forEach { options, value in
            applyProfileBitrate(for: options, on: value.transceiver)
        }
    }

    private func applyProfileBitrate(
        for options: PublishOptions.AudioPublishOptions,
        on transceiver: RTCRtpTransceiver
    ) {
        let current = publishOptions.first { $0 == options } ?? options
        if let bitrate = bitrate(for: current, profile: audioBitrateProfile) {
            applyMaxBitrate(bitrate, on: transceiver)
        }
    }

    private func bitrate(
        for options: PublishOptions.AudioPublishOptions,
        profile: AudioBitrateProfile
    ) -> Int? {
        if profile == .voiceStandard {
            if let mapped = options.bitrateProfiles[profile], mapped > 0 {
                return mapped
            }
            return restoredBitrates[options]
        }
        if restoredBitrates[options] == nil {
            restoredBitrates[options] = options.bitrate
        }
        return options.bitrate(for: profile)
    }

    /// Writes `maxBitrateBps` on the sender's existing encodings.
    /// `bitrate <= 0` clears the cap. An empty encodings list is left
    /// unchanged: synthesizing one encoding would change the send-encoding
    /// count and libwebrtc rejects that assignment. New transceivers are
    /// stamped again from ``addTransceiverIfRequired``.
    private func applyMaxBitrate(
        _ bitrate: Int,
        on transceiver: RTCRtpTransceiver
    ) {
        let params = transceiver.sender.parameters
        guard !params.encodings.isEmpty else { return }
        if bitrate <= 0 {
            params.encodings.forEach { $0.maxBitrateBps = nil }
        } else {
            params.encodings.forEach { $0.maxBitrateBps = bitrate as NSNumber }
        }
        transceiver.sender.parameters = params
    }

    private func registerPrimaryTrackIfPossible(_ callSettings: CallSettings) {
        guard !hasRegisteredPrimaryTrack, callSettings.audioOn else {
            return
        }

        subject.send(
            .added(
                id: sessionID,
                trackType: .audio,
                track: primaryTrack
            )
        )
        hasRegisteredPrimaryTrack = true
    }
}
