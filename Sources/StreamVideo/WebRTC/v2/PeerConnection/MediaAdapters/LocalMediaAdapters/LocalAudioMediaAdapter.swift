//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    /// The stream identifiers for this audio adapter.
    private let streamIds: [String]

    /// The local audio track.
    private(set) var localTrack: RTCAudioTrack?

    /// The RTP transceiver for sending audio.
    private var sender: RTCRtpTransceiver?

    private var lastUpdatedCallSettings: CallSettings.Audio?

    /// The mid (Media Stream Identification) of the sender.
    var mid: String? { sender?.mid }

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
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.subject = subject
        streamIds = ["\(sessionID):audio"]
    }

    /// Cleans up resources when the instance is deallocated.
    deinit {
        Task { @MainActor [sender, localTrack] in
            sender?.sender.track = nil
            localTrack?.isEnabled = false
        }
        if let localTrack {
            log.debug(
                """
                Local audioTrack will be deallocated
                trackId:\(localTrack.trackId)
                isEnabled:\(localTrack.isEnabled)
                """,
                subsystems: .webRTC
            )
        }
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
        let hasAudio = ownCapabilities.contains(.sendAudio)

        if
            hasAudio,
            localTrack == nil || localTrack?.isEnabled == false
        {
            let audioConstrains = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            )
            let audioSource = peerConnectionFactory
                .makeAudioSource(audioConstrains)
            let audioTrack = peerConnectionFactory
                .makeAudioTrack(source: audioSource)

            if sender == nil, settings.audioOn {
                sender = peerConnection.addTransceiver(
                    with: audioTrack,
                    init: RTCRtpTransceiverInit(
                        trackType: .audio,
                        direction: .sendOnly,
                        streamIds: streamIds
                    )
                )
            }
            /// This is important to be false once we setUp as the activation will happen once
            /// publish is called (in order also to inform the SFU via the didUpdateCallSettings).
            audioTrack.isEnabled = false

            log.debug(
                """
                AudioTrack generated
                address:\(Unmanaged.passUnretained(audioTrack).toOpaque())
                trackId:\(audioTrack.trackId)
                mid: \(sender?.mid ?? "-")
                """
            )

            subject.send(
                .added(
                    id: sessionID,
                    trackType: .audio,
                    track: audioTrack
                )
            )

            localTrack = audioTrack
        } else if !hasAudio {
            localTrack?.isEnabled = false
        }
    }

    /// Starts publishing the local audio track.
    func publish() {
        Task { @MainActor in
            guard
                let localTrack,
                localTrack.isEnabled == false || sender?.sender.track == nil
            else {
                return
            }

            if sender == nil {
                sender = peerConnection.addTransceiver(
                    with: localTrack,
                    init: RTCRtpTransceiverInit(
                        trackType: .audio,
                        direction: .sendOnly,
                        streamIds: streamIds
                    )
                )
            } else {
                sender?.sender.track = localTrack
            }
            localTrack.isEnabled = true
        }
    }

    /// Stops publishing the local audio track.
    func unpublish() {
        Task { @MainActor in
            guard let sender, let localTrack else { return }
            localTrack.isEnabled = false
            sender.sender.track = nil
            log.debug("Local audioTrack trackId:\(localTrack.trackId) is now unpublished.")
        }
    }

    /// Updates the local audio media based on new call settings.
    ///
    /// - Parameter settings: The updated call settings.
    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        guard let localTrack else { return }

        guard lastUpdatedCallSettings != settings.audio else {
            return
        }

        let isMuted = !settings.audioOn
        let isLocalMuted = localTrack.isEnabled == false
        
        if isMuted != isLocalMuted {
            try await sfuAdapter.updateTrackMuteState(
                .audio,
                isMuted: isMuted,
                for: sessionID
            )
        }

        if isMuted, localTrack.isEnabled == true {
            unpublish()
        } else if !isMuted {
            publish()
            await audioRecorder.startRecording()
        }

        lastUpdatedCallSettings = settings.audio
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
