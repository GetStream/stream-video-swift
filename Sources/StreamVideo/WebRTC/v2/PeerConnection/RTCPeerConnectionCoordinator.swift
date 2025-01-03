//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    /// `SetPublisher` and `HandleSubscriberOffer` are expected from the SFU to be sent/handled
    /// in a serial manner. The processing queues below ensure that the respective tasks are being executed
    /// serially.
    private let setPublisherProcessingQueue = SerialActorQueue()
    private let subscriberOfferProcessingQueue = SerialActorQueue()

    // MARK: Adapters

    private let mediaAdapter: MediaAdapter
    private let iceAdapter: ICEAdapter
    private let sfuAdapter: SFUAdapter

    private var callSettings: CallSettings

    /// A publisher that we use to observe setUp status. Once the setUp has been completed we expect
    /// a `true` value to be sent. After that, any subsequent observations will rely on the `currentValue`
    /// to know that the setUp completed, without having to wait for it.
    private var setUpSubject: CurrentValueSubject<Bool, Never> = .init(false)
    var videoOptions: VideoOptions
    var audioSettings: AudioSettings
    var publishOptions: PublishOptions {
        didSet { didUpdatePublishOptions(publishOptions) }
    }

    // MARK: State

    var trackPublisher: AnyPublisher<TrackEvent, Never> { mediaAdapter.trackPublisher }
    var disconnectedPublisher: AnyPublisher<Void, Never> {
        peerConnection
            .publisher(eventType: StreamRTCPeerConnection.DidChangeConnectionStateEvent.self)
            .filter { $0.state == .disconnected }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func trackInfo(
        for type: TrackType,
        collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        mediaAdapter.trackInfo(for: type, collectionType: collectionType)
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
    ///   - publishOptions: The publishOptions to use to publish the initial tracks.
    ///   - sfuAdapter: Adapter for communicating with the SFU.
    ///   - audioSession: The audio session to be used.
    ///   - videoCaptureSessionProvider: Provider for video capturing sessions.
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
        publishOptions: PublishOptions,
        sfuAdapter: SFUAdapter,
        videoCaptureSessionProvider: VideoCaptureSessionProvider,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        self.init(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            mediaAdapter: .init(
                sessionID: sessionId,
                peerConnectionType: peerType,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                publishOptions: publishOptions,
                videoCaptureSessionProvider: videoCaptureSessionProvider,
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
        publishOptions: PublishOptions,
        sfuAdapter: SFUAdapter,
        mediaAdapter: MediaAdapter
    ) {
        self.sessionId = sessionId
        self.peerType = peerType
        self.videoOptions = videoOptions
        self.callSettings = callSettings
        self.audioSettings = audioSettings
        self.publishOptions = publishOptions
        self.peerConnection = peerConnection
        self.sfuAdapter = sfuAdapter
        subsystem = peerType == .publisher
            ? .peerConnectionPublisher
            : .peerConnectionSubscriber
        self.mediaAdapter = mediaAdapter

        iceAdapter = .init(
            sessionID: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            sfuAdapter: sfuAdapter
        )

        peerConnection
            .publisher
            .receive(on: DispatchQueue.main)
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
                .log(.debug) { _ in "Publisher will negotiate" }
                .receive(on: dispatchQueue)
                .map { _ in () }
                .sinkTask(queue: setPublisherProcessingQueue) { [weak self] in await self?.negotiate() }
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
        Task { [peerConnection] in await peerConnection.close() }
    }

    func prepareForClosing() async {
        await iceAdapter.stopObserving()
    }

    /// SetUp and negotiation are running concurrently. However, in order to be able to negotiate
    /// successfully, we need to wait for setUp to complete in order to have access to the local tracks.
    /// This method ensures that setUp has been completed before moving forward.
    /// - Note: The default timeout is set to 2 seconds.
    func ensureSetUpHasBeenCompleted() async throws {
        guard !setUpSubject.value else {
            return
        }

        do {
            log.debug(
                "PeerConnection is ready to negotiate but media setUp hasn't completed. Waiting...",
                subsystems: .peerConnectionPublisher
            )

            _ = try await setUpSubject
                .filter { $0 }
                .nextValue(timeout: WebRTCConfiguration.timeout.publisherSetUpBeforeNegotiation)

            log.debug(
                "PeerConnection is now ready to negotiate.",
                subsystems: .peerConnectionPublisher
            )
        } catch {
            throw ClientError("PeerConnection setUp timed-out during negotiation [Error:\(error).].")
        }
    }

    func completeSetUp() {
        setUpSubject.send(true)
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
            
            \(settings)
            
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
            """,
            subsystems: subsystem
        )
        callSettings = settings
        try await mediaAdapter.didUpdateCallSettings(settings)
    }

    func didUpdatePublishOptions(
        _ publishOptions: PublishOptions
    ) {
        Task {
            do {
                try await mediaAdapter.didUpdatePublishOptions(publishOptions)
            } catch {
                log.error(error)
            }
        }
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
            SDP: \(sessionDescription.sdp.replacingOccurrences(of: "\r\n", with: " ").replacingOccurrences(of: "\n", with: " "))
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
            SDP: \(sessionDescription.sdp.replacingOccurrences(of: "\r\n", with: " ").replacingOccurrences(of: "\n", with: " "))
            """,
            subsystems: subsystem
        )
        return try await peerConnection.setRemoteDescription(sessionDescription)
    }

    /// Closes the peer connection.
    func close() async {
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
        await peerConnection.close()
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
            setPublisherProcessingQueue.async { [weak self] in
                await self?.negotiate(constraints: .iceRestartConstraints)
            }
        }
    }

    /// Retrieves the statistics report for the peer connection.
    ///
    /// - Returns: An RTCStatisticsReport containing the connection statistics.
    /// - Throws: An error if retrieving statistics fails.
    func statsReport() async throws -> RTCStatisticsReport? {
        try await peerConnection.statistics()
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
    func zoom(by factor: CGFloat) async throws {
        try await mediaAdapter.zoom(by: factor)
    }

    /// Focuses the camera at a given point.
    ///
    /// - Parameter point: The point in the camera's coordinate system to focus on.
    /// - Throws: An error if focusing fails or is not supported by the current device.
    func focus(at point: CGPoint) async throws {
        try await mediaAdapter.focus(at: point)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The video output to add.
    /// - Throws: An error if adding the video output fails.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await mediaAdapter.addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The video output to remove.
    /// - Throws: An error if removing the video output fails.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await mediaAdapter.removeVideoOutput(videoOutput)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to add.
    /// - Throws: An error if adding the photo output fails.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await mediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The photo output to remove.
    /// - Throws: An error if removing the photo output fails.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await mediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Changes the publish quality with active encodings.
    ///
    /// - Parameter activeEncodings: A set of active encoding identifiers.
    func changePublishQuality(
        with event: Stream_Video_Sfu_Event_ChangePublishQuality
    ) {
        Task {
            await mediaAdapter.changePublishQuality(with: event)
        }
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
    ) async {
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

            let offer = try await createOffer(constraints: constraints)

            try await setLocalDescription(offer)

            try await ensureSetUpHasBeenCompleted()

            let tracksInfo = WebRTCJoinRequestFactory()
                .buildAnnouncedTracks(self, collectionType: .allAvailable)

            validateTracksAndTransceivers(.video, tracksInfo: tracksInfo)
            validateTracksAndTransceivers(.screenshare, tracksInfo: tracksInfo)

            log.debug(
                """
                PeerConnection will setPublisher
                Identifier: \(identifier)
                type:\(peerType)
                sessionID: \(sessionId)
                sfu: \(sfuAdapter.hostname)
                tracksInfo:
                    audio: 
                        \(tracksInfo.filter { $0.trackType == .audio })
                    video: 
                        \(tracksInfo.filter { $0.trackType == .video })
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

    /// Handles a subscriber offer event.
    ///
    /// - Parameter event: The subscriber offer event to handle.
    private func handleSubscriberOffer(
        _ event: Stream_Video_Sfu_Event_SubscriberOffer
    ) async {
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

    /// Configures the subscriber offer observer.
    private func configureSubscriberOfferObserver() {
        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_SubscriberOffer.self)
            .log(.debug, subsystems: subsystem)
            .receive(on: dispatchQueue)
            .sinkTask(queue: subscriberOfferProcessingQueue) { [weak self] in await self?.handleSubscriberOffer($0) }
            .store(in: disposableBag)
    }

    /// Validates that the tracks intended for negotiation with the SFU match the state of the transceivers in
    /// the peer connection.
    ///
    /// This method ensures that the tracks we plan to send during negotiation (as represented by the
    /// `tracksInfo` parameter) are consistent with the transceivers in the peer connection. If there is a
    /// mismatch, an error is logged for debugging purposes.
    ///
    /// - Parameters:
    ///   - trackType: The type of track to validate (e.g., `.audio`, `.video`, or `.screenshare`).
    ///   - tracksInfo: A collection of `TrackInfo` objects representing the tracks announced to
    ///   the SFU during negotiation.
    ///
    /// The validation process compares the set of track IDs in the `tracksInfo` list against the set of
    /// track IDs retrieved from the peer connection's transceivers for the specified `trackType`. If these
    /// sets differ, it indicates a discrepancy between the announced tracks and the transceivers' actual state.
    private func validateTracksAndTransceivers(
        _ trackType: TrackType,
        tracksInfo: [Stream_Video_Sfu_Models_TrackInfo]
    ) {
        let tracks = Set(
            tracksInfo
                .filter {
                    switch (trackType, $0.trackType) {
                    case (.audio, .audio), (.video, .video), (.screenshare, .screenShare):
                        return true
                    default:
                        return false
                    }
                }
                .map(\.trackID)
        )
        let transceivers = Set(
            peerConnection
                .transceivers(for: trackType)
                .compactMap(\.sender.track?.trackId)
        )

        guard tracks != transceivers else {
            return
        }
        log.error(
            """
            PeerConnection tracks and transceivers mismatch for trackType:\(trackType)
            Identifier: \(identifier)
            type:\(peerType)
            sessionID: \(sessionId)
            sfu: \(sfuAdapter.hostname)
            
            tracks: \(tracks.sorted().joined(separator: ","))
            transceivers: \(transceivers.sorted().joined(separator: ","))
            """,
            subsystems: subsystem
        )
    }
}
