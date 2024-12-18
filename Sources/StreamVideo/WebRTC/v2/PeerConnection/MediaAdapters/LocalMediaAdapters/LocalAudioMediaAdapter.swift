//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
final class LocalAudioMediaAdapter: LocalMediaAdapting {

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

    /// The primary audio track for this adapter.
    private let primaryTrack: RTCAudioTrack

    /// The last applied audio call settings.
    private var lastUpdatedCallSettings: CallSettings.Audio?

    /// A publisher that emits events related to audio tracks.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Initializes a new instance of `LocalAudioMediaAdapter`.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - publishOptions: The options for publishing audio tracks.
    ///   - subject: A publisher that emits track events.
    init(
        sessionID: String,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        publishOptions: [PublishOptions.AudioPublishOptions],
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.publishOptions = publishOptions
        self.subject = subject

        // Create the primary audio track for the session.
        let source = peerConnectionFactory.makeAudioSource(.defaultConstraints)
        let track = peerConnectionFactory.makeAudioTrack(source: source)
        primaryTrack = track
        streamIds = ["\(sessionID):audio"]

        // Disable the primary track by default.
        track.isEnabled = false
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        Task { @MainActor [transceiverStorage] in
            transceiverStorage.removeAll()
        }
        log.debug(
            """
            Local audio tracks will be deallocated:
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
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
        // Notify that the primary audio track has been added.
        subject.send(
            .added(
                id: sessionID,
                trackType: .audio,
                track: primaryTrack
            )
        )
    }

    /// Starts publishing the local audio track.
    ///
    /// This enables the primary track and creates additional transceivers based
    /// on the current publish options. It also starts the audio recorder.
    func publish() {
        Task { @MainActor in
            guard !primaryTrack.isEnabled else { return }

            primaryTrack.isEnabled = true

            publishOptions.forEach {
                addTransceiverIfRequired(
                    for: $0,
                    with: primaryTrack.clone(from: peerConnectionFactory)
                )
            }

            let activePublishOptions = Set(self.publishOptions)
            transceiverStorage
                .forEach { $0.value.sender.track?.isEnabled = activePublishOptions.contains($0.key) }

            await audioRecorder.startRecording()

            log.debug(
                """
                Local audio tracks are now published:
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Stops publishing the local audio track.
    ///
    /// This disables the primary track and all associated transceivers.
    func unpublish() {
        Task { @MainActor [weak self] in
            guard let self, primaryTrack.isEnabled else { return }

            primaryTrack.isEnabled = false

            transceiverStorage.forEach {
                $0.value.sender.track?.isEnabled = false
            }

            log.debug(
                """
                Local audio tracks are now unpublished:
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Updates the local audio media based on new call settings.
    ///
    /// - Parameter settings: The updated settings for the call.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
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
            unpublish()
        } else if !isMuted {
            publish()
        }

        lastUpdatedCallSettings = settings.audio
    }

    /// Updates the publish options for the local audio track.
    ///
    /// - Parameter publishOptions: The new publish options.
    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        guard primaryTrack.isEnabled else { return }

        self.publishOptions = publishOptions.audio

        for option in self.publishOptions {
            addTransceiverIfRequired(
                for: option,
                with: primaryTrack.clone(from: peerConnectionFactory)
            )
        }

        let activePublishOptions = Set(self.publishOptions)

        transceiverStorage
            .forEach { $0.value.sender.track?.isEnabled = activePublishOptions.contains($0.key) }

        log.debug(
            """
            Local audio tracks updated:
                PublishOptions: \(self.publishOptions)
                TransceiverStorage: \(transceiverStorage)
            """,
            subsystems: .webRTC
        )
    }

    /// Returns track information for the local audio tracks.
    ///
    /// - Returns: An array of `Stream_Video_Sfu_Models_TrackInfo` representing
    ///   the local audio tracks.
    func trackInfo() -> [Stream_Video_Sfu_Models_TrackInfo] {
        transceiverStorage
            .filter { $0.value.sender.track != nil }
            .map { _, transceiver in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .audio
                trackInfo.trackID = transceiver.sender.track?.trackId ?? ""
                trackInfo.mid = transceiver.mid
                trackInfo.muted = !(transceiver.sender.track?.isEnabled ?? true)
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

    // MARK: - Private Helpers

    /// Adds or updates a transceiver for a given audio track and publish option.
    ///
    /// - Parameters:
    ///   - options: The options for publishing the audio track.
    ///   - track: The audio track to be added or updated.
    private func addTransceiverIfRequired(
        for options: PublishOptions.AudioPublishOptions,
        with track: RTCAudioTrack
    ) {
        guard !transceiverStorage.contains(key: options) else {
            return
        }

        let transceiver = peerConnection.addTransceiver(
            trackType: .audio,
            with: track,
            init: .init(
                direction: .sendOnly,
                streamIds: streamIds,
                audioOptions: options
            )
        )
        transceiverStorage.set(transceiver, for: options)
    }
}
