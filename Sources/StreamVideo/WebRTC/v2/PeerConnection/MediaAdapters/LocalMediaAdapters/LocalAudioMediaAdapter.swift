//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class LocalAudioMediaAdapter: LocalMediaAdapting {

    @Injected(\.callAudioRecorder) private var audioRecorder

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private var sfuAdapter: SFUAdapter
    private let audioSession: AudioSession
    private let streamIds: [String]

    private(set) var localTrack: RTCAudioTrack?
    private var sender: RTCRtpTransceiver?

    var mid: String? { sender?.mid }

    let subject: PassthroughSubject<TrackEvent, Never>

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.audioSession = audioSession
        self.subject = subject
        streamIds = ["\(sessionID):audio"]
    }

    deinit {
        sender?.sender.track = nil
        localTrack?.isEnabled = false
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

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        let hasAudio = ownCapabilities.contains(.sendAudio)

        if hasAudio, localTrack == nil || localTrack?.isEnabled == false {
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

    func publish() {
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

    func unpublish() {
        guard let sender, let localTrack else { return }
        sender.sender.track = nil
        localTrack.isEnabled = false
        log.debug("Local audioTrack trackId:\(localTrack.trackId) is now unpublished.")
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        guard let localTrack else { return }
        let isMuted = !settings.audioOn
        let isLocalMuted = localTrack.isEnabled == false
        guard isMuted != isLocalMuted || sender == nil else {
            return
        }

        try await sfuAdapter.updateTrackMuteState(
            .audio,
            isMuted: isMuted,
            for: sessionID
        )

        await audioSession.configure(
            audioOn: settings.audioOn,
            speakerOn: settings.speakerOn
        )

        if isMuted, localTrack.isEnabled == true {
            unpublish()
        } else if !isMuted {
            publish()
            await audioRecorder.startRecording()
            let isActive = await audioSession.isActive
            let isAudioEnabled = await audioSession.isAudioEnabled
            log.debug(
                """
                Local audioTrack is now published.
                isEnabled: \(localTrack.isEnabled == true)
                senderHasCorrectTrack: \(sender?.sender.track == localTrack)
                trackId:\(localTrack.trackId)
                audioSession.isActive: \(isActive)
                audioSession.isAudioEnabled: \(isAudioEnabled)
                """
            )
        }
    }
}
