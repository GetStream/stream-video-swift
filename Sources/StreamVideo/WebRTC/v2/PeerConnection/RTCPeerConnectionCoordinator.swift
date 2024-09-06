//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

class RTCPeerConnectionCoordinator: @unchecked Sendable {

    enum Action {
        case addTrack(
            RTCMediaStreamTrack,
            trackType: TrackType,
            streamIds: [String]
        )

        case addTransceiver(
            RTCMediaStreamTrack,
            trackType: TrackType,
            direction: RTCRtpTransceiverDirection = .sendOnly,
            streamIds: [String]
        )

        case restartICE
    }

    private let identifier = UUID()
    private let sessionId: String
    private let peerType: PeerConnectionType
    private let peerConnection: StreamRTCPeerConnection
    private let subsystem: LogSubsystem
    private let disposableBag: DisposableBag = .init()
    private let dispatchQueue = DispatchQueue(label: "io.getstream.peerconnection.serial.offer.queue")
    private let audioSession: AudioSession

    // MARK: Adapters

    private let mediaAdapter: MediaAdapter
    private let iceAdapter: ICEAdapter
    private let sfuAdapter: SFUAdapter

    private var callSettings: CallSettings
    var videoOptions: VideoOptions
    var audioSettings: AudioSettings

    // MARK: State

    var trackPublisher: AnyPublisher<TrackEvent, Never> { mediaAdapter.trackPublisher }
    var disconnectedPublisher: AnyPublisher<Void, Never> {
        peerConnection
            .publisher(eventType: RTCPeerConnection.DidChangeConnectionStateEvent.self)
            .filter { $0.state == .disconnected }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func localTrack(of type: TrackType) -> RTCMediaStreamTrack? {
        mediaAdapter.localTrack(of: type)
    }

    func mid(for type: TrackType) -> String? {
        mediaAdapter.mid(for: type)
    }

    init(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.sessionId = sessionId
        self.peerType = peerType
        self.videoOptions = videoOptions
        self.callSettings = callSettings
        self.audioSettings = audioSettings
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter
        subsystem = peerType == .publisher
            ? .peerConnectionPublisher
            : .peerConnectionSubscriber
        self.audioSession = audioSession

        iceAdapter = .init(
            sessionID: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            sfuAdapter: sfuAdapter
        )

        mediaAdapter = .init(
            sessionID: sessionId,
            peerConnectionType: peerType,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            sfuAdapter: sfuAdapter,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )

        peerConnection
            .publisher
            .sink { [identifier, subsystem] in
                if let failedToGatherEvent = $0 as? RTCPeerConnection.ICECandidateFailedToGatherEvent {
                    log.warning(
                        """
                        PeerConnection failed to gather ICE candidates:
                        Identifier: \(identifier)
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \(failedToGatherEvent.errorEvent.errorText)
                        """,
                        subsystems: subsystem
                    )
                } else {
                    log.debug(
                        """
                        PeerConnection received event:
                        Identifier: \(identifier)
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \($0)
                        """,
                        subsystems: subsystem
                    )
                }
            }
            .store(in: disposableBag)

        if peerType == .publisher {
            peerConnection
                .publisher(eventType: RTCPeerConnection.ShouldNegotiateEvent.self)
                .receive(on: dispatchQueue)
                .map { _ in () }
                .sink { [weak self] in self?.negotiate() }
                .store(in: disposableBag)
        } else {
            configureSubscriberOfferObserver()
            sfuAdapter
                .refreshPublisher
                .sink { [weak self] in self?.configureSubscriberOfferObserver() }
                .store(in: disposableBag)
        }
    }

    deinit {
        log.debug(
            """
            Deallocating PeerConnection
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        disposableBag.removeAll()
        peerConnection.close()
    }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        log.debug(
            """
            PeerConnection will setUp:
            Identifier: \(identifier)
            Session ID: \(sessionId)
            Connection type: \(peerType)
            SFU: \(sfuAdapter.hostname)

            CallSettings:
                audioOn: \(settings.audioOn)
                videoOn: \(settings.videoOn)
                audioOutputOn: \(settings.audioOutputOn)
                speakerOn: \(settings.speakerOn)

            ownCapabilities:
                hasAudio: \(ownCapabilities.contains(.sendAudio))
                hasVideo: \(ownCapabilities.contains(.sendVideo))
            """,
            subsystems: subsystem
        )
        try await mediaAdapter.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        let isActive = await audioSession.isActive
        log.debug(
            """
            PeerConnection will setUp:
            Identifier: \(identifier)
            Session ID: \(sessionId)
            Connection type: \(peerType)
            SFU: \(sfuAdapter.hostname)
            
            CallSettings:
                audioOn: \(settings.audioOn)
                videoOn: \(settings.videoOn)
                audioOutputOn: \(settings.audioOutputOn)
                speakerOn: \(settings.speakerOn)

            AudioSession enabled: \(isActive)
            """,
            subsystems: subsystem
        )
        callSettings = settings
        try await mediaAdapter.didUpdateCallSettings(settings)
    }

    // MARK: - Actions

    func createOffer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        log.debug(
            """
            PeerConnection will create offer
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        return try await peerConnection.offer(for: constraints)
    }

    func createAnswer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        log.debug(
            """
            PeerConnection will create answer
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        return try await peerConnection.answer(for: constraints)
    }

    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        log.debug(
            """
            PeerConnection will set localDescription
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        return try await peerConnection.setLocalDescription(sessionDescription)
    }

    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        log.debug(
            """
            PeerConnection will set remoteDescription
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        return try await peerConnection.setRemoteDescription(sessionDescription)
    }

    func close() {
        log.debug(
            """
            Closing PeerConnection
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        disposableBag.removeAll()
        peerConnection.close()
    }

    func restartICE() {
        log.debug(
            """
            PeerConnection will restart ICE
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """,
            subsystems: subsystem
        )
        switch peerType {
        case .subscriber:
            peerConnection.restartIce()
        case .publisher:
            negotiate(constraints: .iceRestartConstraints)
        }
    }

    func statsReport() async throws -> RTCStatisticsReport {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(throwing: ClientError.Unexpected())
            }
            peerConnection.statistics { report in
                continuation.resume(returning: report)
            }
        }
    }

    // MARK: - Audio

    func didUpdateAudioSessionState(_ isEnabled: Bool) async {
        log.debug(
            """
            PeerConnection will update audioSession state
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            audioSession state: \(isEnabled)
            """,
            subsystems: subsystem
        )
        await mediaAdapter.didUpdateAudioSessionState(isEnabled)
    }

    func didUpdateAudioSessionSpeakerState(
        _ isEnabled: Bool,
        with audioSessionEnabled: Bool
    ) async {
        log.debug(
            """
            PeerConnection will update audioSession speakerState
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            audioSession speakerState: \(isEnabled)
            """,
            subsystems: subsystem
        )
        await mediaAdapter.didUpdateAudioSessionSpeakerState(
            isEnabled,
            with: audioSessionEnabled
        )
    }

    // MARK: - Video

    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        log.debug(
            """
            PeerConnection will update camera position
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            camera position: \(position)
            """,
            subsystems: subsystem
        )
        try await mediaAdapter.didUpdateCameraPosition(position)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        log.debug(
            """
            PeerConnection will set videoFilter
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            videoFilter: \(videoFilter?.id ?? "-")
            """,
            subsystems: subsystem
        )
        mediaAdapter.setVideoFilter(videoFilter)
    }

    func zoom(by factor: CGFloat) throws {
        try mediaAdapter.zoom(by: factor)
    }

    func focus(at point: CGPoint) throws {
        try mediaAdapter.focus(at: point)
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try mediaAdapter.addVideoOutput(videoOutput)
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try mediaAdapter.removeVideoOutput(videoOutput)
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try mediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try mediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }

    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        mediaAdapter.changePublishQuality(with: activeEncodings)
    }

    // MARK: - ScreenSharing

    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await mediaAdapter.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
    }

    func stopScreenSharing() async throws {
        try await mediaAdapter.stopScreenSharing()
    }

    // MARK: - Private helpers

    private func negotiate(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                log.debug(
                    """
                    PeerConnection will negotiate
                    Identifier: \(identifier)
                    type:\(peerType)
                    sessionID: \(sessionId)
                    sfu: \(sfuAdapter.hostname)
                    """,
                    subsystems: subsystem
                )

                let offer = try await self
                    .createOffer(constraints: constraints)
                    .withOpusDTX(audioSettings.opusDtxEnabled)
                    .withRedundantCoding(audioSettings.redundantCodingEnabled)

                try await setLocalDescription(offer)

                let tracksInfo = WebRTCJoinRequestFactory().buildAnnouncedTracks(
                    self,
                    videoOptions: videoOptions
                )

                log.debug(
                    """
                    PeerConnection will setPublisher
                    Identifier: \(identifier)
                    type:\(peerType)
                    sessionID: \(sessionId)
                    sfu: \(sfuAdapter.hostname)
                    tracksInfo:
                        hasAudio: \(tracksInfo.contains { $0.trackType == .audio })
                        hasVideo: \(tracksInfo.contains { $0.trackType == .video })
                        hasScreenSharing: \(tracksInfo.contains { $0.trackType == .screenShare })
                    """,
                    subsystems: subsystem
                )
                let sessionDescription = try await sfuAdapter.setPublisher(
                    sessionDescription: offer.sdp,
                    tracks: tracksInfo,
                    for: sessionId
                )

                try await setRemoteDescription(
                    .init(
                        type: .answer,
                        sdp: sessionDescription.sdp
                    )
                )
            } catch {
                log.error(error, subsystems: subsystem)
            }
        }
    }

    private func handleSubscriberOffer(
        _ event: Stream_Video_Sfu_Event_SubscriberOffer
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                log.debug(
                    """
                    PeerConnection will handleSubscriberOffer
                    Identifier: \(identifier)
                    type:\(peerType)
                    sessionID: \(sessionId)
                    sfu: \(sfuAdapter.hostname)
                    """,
                    subsystems: subsystem
                )

                let offerSdp = event.sdp
                try await setRemoteDescription(
                    .init(
                        type: .offer,
                        sdp: offerSdp
                    )
                )

                let answer = try await createAnswer()
                try await setLocalDescription(answer)

                try await sfuAdapter.sendAnswer(
                    sessionDescription: answer.sdp,
                    peerType: .subscriber,
                    for: sessionId
                )
                log.debug("Subscriber offer was handled.", subsystems: subsystem)
            } catch {
                log.error(
                    "Error handling offer event",
                    subsystems: subsystem,
                    error: error
                )
            }
        }
    }

    private func configureSubscriberOfferObserver() {
        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_SubscriberOffer.self)
            .log(.debug, subsystems: subsystem)
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.handleSubscriberOffer($0) }
            .store(in: disposableBag)
    }
}
