//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Coordinates the peer connection, managing media, ICE, and SFU interactions.
class RTCPeerConnectionCoordinator: @unchecked Sendable {

    /// Represents actions that can be performed on the peer connection.
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

    // MARK: - Properties

    private let identifier = UUID()
    private let sessionId: String
    private let peerType: PeerConnectionType
    private let peerConnection: StreamRTCPeerConnectionProtocol
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
            .publisher(eventType: StreamRTCPeerConnection.DidChangeConnectionStateEvent.self)
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

    /// Initializes the RTCPeerConnectionCoordinator with necessary dependencies.
    ///
    /// - Parameters:
    ///   - sessionId: The unique identifier for the session.
    ///   - peerType: The type of peer connection (publisher or subscriber).
    ///   - peerConnection: The underlying WebRTC peer connection.
    ///   - peerConnectionFactory: Factory for creating WebRTC objects.
    ///   - videoOptions: Configuration options for video.
    ///   - videoConfig: Configuration for video processing.
    ///   - callSettings: Settings for the current call.
    ///   - audioSettings: Settings for audio processing.
    ///   - sfuAdapter: Adapter for communicating with the SFU.
    ///   - audioSession: The audio session to be used.
    ///   - screenShareSessionProvider: Provider for screen sharing sessions.
    convenience init(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        peerConnectionFactory: PeerConnectionFactory,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.init(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            mediaAdapter: .init(
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
        )
    }

    init(
        sessionId: String,
        peerType: PeerConnectionType,
        peerConnection: StreamRTCPeerConnectionProtocol,
        videoOptions: VideoOptions,
        callSettings: CallSettings,
        audioSettings: AudioSettings,
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession,
        mediaAdapter: MediaAdapter
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
        self.mediaAdapter = mediaAdapter

        iceAdapter = .init(
            sessionID: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            sfuAdapter: sfuAdapter
        )

        peerConnection
            .publisher
            .sink { [identifier, subsystem] in
                if let failedToGatherEvent = $0 as? StreamRTCPeerConnection.ICECandidateFailedToGatherEvent {
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
                .publisher(eventType: StreamRTCPeerConnection.ShouldNegotiateEvent.self)
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

    func prepareForClosing() async {
        await iceAdapter.stopObserving()
    }

    /// Sets up the peer connection with given settings and capabilities.
    ///
    /// - Parameters:
    ///   - settings: The call settings to apply.
    ///   - ownCapabilities: The capabilities of the local participant.
    /// - Throws: An error if the setup process fails.
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
                cameraPosition: \(settings.cameraPosition)
            
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

    /// Updates the call settings.
    ///
    /// - Parameter settings: The new call settings to apply.
    /// - Throws: An error if updating the settings fails.
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

    /// Creates an offer for the peer connection.
    ///
    /// - Parameter constraints: The media constraints to use when creating the offer.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the offer creation fails.
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

    /// Creates an answer for the peer connection.
    ///
    /// - Parameter constraints: The media constraints to use when creating the answer.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the answer creation fails.
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

    /// Sets the local description for the peer connection.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the local description.
    /// - Throws: An error if setting the local description fails.
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

    /// Sets the remote description for the peer connection.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the remote description.
    /// - Throws: An error if setting the remote description fails.
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

    /// Closes the peer connection.
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

    /// Restarts ICE for the peer connection.
    ///
    /// - Note: For publisher connections, this will trigger a new offer. For subscriber
    ///         connections, it will directly restart ICE on the peer connection.
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

    /// Retrieves the statistics report for the peer connection.
    ///
    /// - Returns: An RTCStatisticsReport containing the connection statistics.
    /// - Throws: An error if retrieving statistics fails.
    func statsReport() async throws -> RTCStatisticsReport? {
        try await peerConnection.statistics()
    }

    // MARK: - Audio

    /// Updates the audio session state.
    ///
    /// - Parameter isEnabled: Whether the audio session should be enabled or disabled.
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

    /// Updates the audio session speaker state.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether the speaker should be enabled or disabled.
    ///   - audioSessionEnabled: Whether the audio session is currently enabled.
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

    /// Updates the camera position.
    ///
    /// - Parameter position: The new camera position to use.
    /// - Throws: An error if changing the camera position fails.
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

    /// Sets the video filter.
    ///
    /// - Parameter videoFilter: The video filter to apply, or nil to remove the current filter.
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

    /// Zooms the camera by a given factor.
    ///
    /// - Parameter factor: The zoom factor to apply.
    /// - Throws: An error if zooming fails or is not supported by the current device.
    func zoom(by factor: CGFloat) throws {
        try mediaAdapter.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point in the camera's coordinate system to focus on.
    /// - Throws: An error if focusing fails or is not supported by the current device.
    func focus(at point: CGPoint) throws {
        try mediaAdapter.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    /// - Throws: An error if adding the video output fails.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try mediaAdapter.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    /// - Throws: An error if removing the video output fails.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try mediaAdapter.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    /// - Throws: An error if adding the photo output fails.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try mediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    /// - Throws: An error if removing the photo output fails.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try mediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Changes the publish quality with active encodings.
    ///
    /// - Parameter activeEncodings: A set of active encoding identifiers.
    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        mediaAdapter.changePublishQuality(with: activeEncodings)
    }

    // MARK: - ScreenSharing

    /// Begins screen sharing of a specified type.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to begin.
    ///   - ownCapabilities: The capabilities of the local participant.
    /// - Throws: An error if starting screen sharing fails.
    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await mediaAdapter.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
    }

    /// Stops screen sharing.
    ///
    /// - Throws: An error if stopping screen sharing fails.
    func stopScreenSharing() async throws {
        try await mediaAdapter.stopScreenSharing()
    }

    // MARK: - Private helpers

    /// Negotiates the peer connection.
    ///
    /// - Parameter constraints: The media constraints to use for negotiation.
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

    /// Handles a subscriber offer event.
    ///
    /// - Parameter event: The subscriber offer event to handle.
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

    /// Configures the subscriber offer observer.
    private func configureSubscriberOfferObserver() {
        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_SubscriberOffer.self)
            .log(.debug, subsystems: subsystem)
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.handleSubscriberOffer($0) }
            .store(in: disposableBag)
    }
}
