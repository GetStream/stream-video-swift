//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class RTCPeerConnectionCoordinator: @unchecked Sendable {

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

    private let sessionId: String
    private let peerType: PeerConnectionType
    private let peerConnection: RTCPeerConnection
    private let subsystem: LogSubsystem
    private let disposableBag: DisposableBag = .init()
    private let dispatchQueue = DispatchQueue(label: "io.getstream.peerconnection.serial.offer.queue")

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
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession
    ) {
        self.sessionId = sessionId
        self.peerType = peerType
        self.videoOptions = videoOptions
        self.callSettings = callSettings
        self.audioSettings = audioSettings
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter
        self.subsystem = peerType == .publisher
        ? .peerConnection_publisher
        : .peerConnection_subscriber

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
            audioSession: audioSession
        )

        peerConnection
            .publisher
            .sink {
                if let failedToGatherEvent = $0 as? RTCPeerConnection.ICECandidateFailedToGatherEvent {
                    log.warning(
                        """
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \(failedToGatherEvent.errorEvent.errorText)
                        """
                    )
                } else {
                    log.debug(
                        """
                        Session ID: \(sessionId)
                        Connection type: \(peerType)
                        SFU: \(sfuAdapter.hostname)
                        Event: \($0)
                        """
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
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            """
        )
        disposableBag.removeAll()
        // mediaAdapter.close()
        peerConnection.close()
    }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await mediaAdapter.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        self.callSettings = settings
        try await mediaAdapter.didUpdateCallSettings(settings)
    }

    // MARK: - Actions

    func createOffer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        try await peerConnection.offer(for: constraints)
    }

    func createAnswer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        try await peerConnection.answer(for: constraints)
    }

    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await peerConnection.setLocalDescription(sessionDescription)
    }

    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await peerConnection.setRemoteDescription(sessionDescription)
    }

    func close() {
        peerConnection.close()
    }

    func restartICE() {
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
        await mediaAdapter.didUpdateAudioSessionState(isEnabled)
    }

    func didUpdateAudioSessionSpeakerState(
        _ isEnabled: Bool,
        with audioSessionEnabled: Bool
    ) async  {
        await mediaAdapter.didUpdateAudioSessionSpeakerState(
            isEnabled,
            with: audioSessionEnabled
        )
    }

    // MARK: - Video

    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await mediaAdapter.didUpdateCameraPosition(position)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
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

    func stopScreenSharing() {
        mediaAdapter.stopScreenSharing()
    }

    // MARK: - Private helpers

    private func negotiate(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let offer = try await self
                    .createOffer(constraints: constraints)
                    .withOpusDTX(audioSettings.opusDtxEnabled)
                    .withRedundantCoding(audioSettings.redundantCodingEnabled)

                try await setLocalDescription(offer)

                let tracksInfo: [Stream_Video_Sfu_Models_TrackInfo] = [
                    TrackType.audio,
                    .video,
                    .screenshare
                ]
                    .compactMap { trackType in
                        switch trackType {
                        case .audio where self.mediaAdapter.mid(for: .audio) != nil:
                            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                            trackInfo.trackType = .audio
                            trackInfo.trackID = self.mediaAdapter.localTrack(of: .audio)?.trackId ?? ""
                            trackInfo.mid = self.self.mediaAdapter.mid(for: .audio) ?? ""
                            return trackInfo

                        case .video where self.mediaAdapter.mid(for: .video) != nil:
                            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                            trackInfo.trackType = .video
                            trackInfo.trackID = self.mediaAdapter.localTrack(of: .video)?.trackId ?? ""
                            trackInfo.mid = self.mediaAdapter.mid(for: .video) ?? ""
                            trackInfo.layers = self.videoOptions
                                .supportedCodecs
                                .map { Stream_Video_Sfu_Models_VideoLayer.init($0) }
                            return trackInfo

                        case .screenshare where self.mediaAdapter.mid(for: .screenshare) != nil:
                            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
                            trackInfo.trackType = .screenShare
                            trackInfo.trackID = self.mediaAdapter.localTrack(of: .screenshare)?.trackId ?? ""
                            trackInfo.mid = self.mediaAdapter.mid(for: .screenshare) ?? ""
                            trackInfo.layers = [VideoCodec.screenshare]
                                .map { Stream_Video_Sfu_Models_VideoLayer.init($0, fps: 15) }
                            return trackInfo

                        default:
                            return nil
                        }
                    }

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
