//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class that manages local audio media for a call session.
final class LocalAudioMediaAdapter: LocalMediaAdapting {

    /// The audio recorder for the call.
    @Injected(\.callAudioRecorder) private var audioRecorder

    /// The unique identifier for the current session.
    private let sessionID: String

    /// The WebRTC peer connection.
    private let peerConnection: StreamRTCPeerConnectionProtocol

    /// The factory for creating WebRTC peer connection components.
    private let peerConnectionFactory: PeerConnectionFactory

    /// The adapter for communicating with the Selective Forwarding Unit (SFU).
    private var sfuAdapter: SFUAdapter

    private var publishOptions: [PublishOptions.AudioPublishOptions]

    /// The stream identifiers for this audio adapter.
    private let streamIds: [String]

    private let transceiverStorage = MediaTransceiverStorage<PublishOptions.AudioPublishOptions>(for: .audio)

    private let primaryTrack: RTCAudioTrack

    /// The RTP transceiver for sending audio.

    private var lastUpdatedCallSettings: CallSettings.Audio?

    /// A publisher that emits track events.
    let subject: PassthroughSubject<TrackEvent, Never>

    /// Initializes a new instance of the local audio media adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The unique identifier for the current session.
    ///   - peerConnection: The WebRTC peer connection.
    ///   - peerConnectionFactory: The factory for creating WebRTC peer connection components.
    ///   - sfuAdapter: The adapter for communicating with the SFU.
    ///   - audioSession: The audio session manager.
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
        let source = peerConnectionFactory.makeAudioSource(.defaultConstraints)
        let track = peerConnectionFactory.makeAudioTrack(source: source)
        primaryTrack = track
        streamIds = ["\(sessionID):audio"]

        track.isEnabled = false
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        Task { @MainActor [transceiverStorage] in
            transceiverStorage.removeAll()
        }
        log.debug(
            """
            Local audioTracks will be deallocated
                primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
            """,
            subsystems: .webRTC
        )
    }

    // MARK: - LocalMediaManaging

    /// Sets up the local audio media with the given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to configure the audio.
    ///   - ownCapabilities: The capabilities of the local participant.
    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        subject.send(
            .added(
                id: sessionID,
                trackType: .audio,
                track: primaryTrack
            )
        )
    }

    /// Starts publishing the local audio track.
    func publish() {
        Task { @MainActor in
            guard
                !primaryTrack.isEnabled
            else {
                return
            }

            primaryTrack.isEnabled = true

            publishOptions
                .forEach {
                    addOrUpdateTransceiver(
                        for: $0,
                        with: primaryTrack.clone(from: peerConnectionFactory)
                    )
                }

            await audioRecorder.startRecording()

            log.debug(
                """
                Local audioTracks are now published
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Stops publishing the local audio track.
    func unpublish() {
        Task { @MainActor [weak self] in
            guard
                let self,
                primaryTrack.isEnabled
            else {
                return
            }

            primaryTrack.isEnabled = false

            transceiverStorage
                .forEach { $0.value.sender.track?.isEnabled = false }

            log.debug(
                """
                Local audioTracks are now unpublished:
                    primary: \(primaryTrack.trackId) isEnabled:\(primaryTrack.isEnabled)
                    clones: \(transceiverStorage.compactMap(\.value.sender.track?.trackId).joined(separator: ","))
                """,
                subsystems: .webRTC
            )
        }
    }

    /// Updates the local audio media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        guard lastUpdatedCallSettings != settings.audio else {
            return
        }

        let isMuted = !settings.audioOn
        let isLocalMuted = primaryTrack.isEnabled == false

        if isMuted != isLocalMuted {
            try await sfuAdapter.updateTrackMuteState(
                .audio,
                isMuted: isMuted,
                for: sessionID
            )
        }

        if isMuted, primaryTrack.isEnabled == true {
            unpublish()
        } else if !isMuted {
            publish()
        }

        lastUpdatedCallSettings = settings.audio
    }

    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) async throws {
        guard primaryTrack.isEnabled else { return }

        self.publishOptions = publishOptions.audio

        for publishOption in self.publishOptions {
            addOrUpdateTransceiver(
                for: publishOption,
                with: primaryTrack.clone(from: peerConnectionFactory)
            )
        }

        let activePublishOptions = Set(self.publishOptions)

        transceiverStorage
            .filter { !activePublishOptions.contains($0.key) }
            .forEach { $0.value.sender.track = nil }

        log.debug(
            """
            Local audioTracks updated with:
                PublishOptions:
                    \(self.publishOptions)
                
                TransceiverStorage:
                    \(transceiverStorage)
            """,
            subsystems: .webRTC
        )
    }

    func changePublishQuality(
        with layerSettings: [Stream_Video_Sfu_Event_AudioSender]
    ) { /* No-op */ }

    func trackInfo() -> [Stream_Video_Sfu_Models_TrackInfo] {
        transceiverStorage
            .filter { $0.value.sender.track != nil }
            .map { _, transceiver in
                var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                trackInfo.trackType = .audio
                trackInfo.trackID = transceiver.sender.track?.trackId ?? ""
                trackInfo.mid = transceiver.mid
                trackInfo.muted = transceiver.sender.track?.isEnabled ?? true
                return trackInfo
            }
    }

    // MARK: - Private Helpers

    private func addOrUpdateTransceiver(
        for options: PublishOptions.AudioPublishOptions,
        with track: RTCAudioTrack
    ) {
        if let transceiver = transceiverStorage.get(for: options) {
            transceiver.sender.track = track
        } else {
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
}

extension RTCAudioTrack {

    func clone(from factory: PeerConnectionFactory) -> RTCAudioTrack {
        let result = factory.makeAudioTrack(source: source)
        result.isEnabled = isEnabled
        return result
    }
}

extension RTCVideoTrack {

    func clone(from factory: PeerConnectionFactory) -> RTCVideoTrack {
        let result = factory.makeVideoTrack(source: source)
        result.isEnabled = isEnabled
        return result
    }
}

extension CallSettings {

    struct Audio: Equatable {
        var micOn: Bool
        var speakerOn: Bool
        var audioSessionOn: Bool
    }

    var audio: Audio {
        .init(
            micOn: audioOn,
            speakerOn: speakerOn,
            audioSessionOn: audioOutputOn
        )
    }
}
