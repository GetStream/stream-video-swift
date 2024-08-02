//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Class that handles a particular call.
class CallController: @unchecked Sendable {

    private lazy var webRTCClient: WebRTCClient = {
        environment.webRTCBuilder(
            user,
            apiKey,
            callCid(from: callId, callType: callType),
            videoConfig,
            .init(),
            CallAuthenticator { [weak self, callId] create in
                if let self {
                    return try await authenticateCall(create: create)
                } else {
                    throw ClientError("Unable to authenticate callId:\(callId).")
                }
            }
        )
    }()

    weak var call: Call?
    private let user: User
    private let callId: String
    private let callType: String
    private let apiKey: String
    private let defaultAPI: DefaultAPI
    private let videoConfig: VideoConfig
    private let sfuReconnectionTime: CGFloat
    private var reconnectionDate: Date?
    private let environment: CallController.Environment
    private var cachedLocation: String?
    private var currentSFU: String?

    private let joinCallResponseSubject = CurrentValueSubject<JoinCallResponse?, Never>(nil)
    private var joinCallResponseFetchObserver: AnyCancellable?
    private var webRTCClientSessionIDObserver: AnyCancellable?

    init(
        defaultAPI: DefaultAPI,
        user: User,
        callId: String,
        callType: String,
        apiKey: String,
        videoConfig: VideoConfig,
        cachedLocation: String?,
        environment: CallController.Environment = .init()
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.apiKey = apiKey
        self.videoConfig = videoConfig
        sfuReconnectionTime = environment.sfuReconnectionTime
        self.environment = environment
        self.defaultAPI = defaultAPI
        self.cachedLocation = cachedLocation

        _ = webRTCClient
        webRTCClient.delegate = self

        handleParticipantsUpdated()
        handleParticipantCountUpdated()
        webRTCClientSessionIDObserver = webRTCClient
            .$sessionID
            .sink { [weak self] sessionID in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    call?.state.sessionId = sessionID
                }
            }

        joinCallResponseFetchObserver = joinCallResponseSubject
            .compactMap { $0 }
            .sink { [weak self] in self?.didFetch($0) }
    }

    /// Joins a call with the provided information.
    /// - Parameters:
    ///  - callType: the type of the call
    ///  - callId: the id of the call
    ///  - callSettings: the current call settings
    ///  - videoOptions: configuration options about the video
    ///  - options: create call options
    ///  - migratingFrom: if SFU migration is being performed
    ///  - ring: whether ringing events should be handled
    ///  - notify: whether uses should be notified about the call
    /// - Returns: a newly created `Call`.
    @discardableResult
    func joinCall(
        create: Bool = true,
        callType: String,
        callId: String,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        migratingFrom: String? = nil,
        sessionID: String? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        try await webRTCClient.connect()
        guard let response = joinCallResponseSubject.value else {
            await webRTCClient.cleanUp()
            throw ClientError("Unable to connect to call callId:\(callId).")
        }
        return response
    }

    /// Changes the audio state for the current user.
    /// - Parameter isEnabled: whether audio should be enabled.
    func changeAudioState(isEnabled: Bool) async throws {
        try await webRTCClient.changeAudioState(isEnabled: isEnabled)
    }

    /// Changes the video state for the current user.
    /// - Parameter isEnabled: whether video should be enabled.
    func changeVideoState(isEnabled: Bool) async throws {
        try await webRTCClient.changeVideoState(isEnabled: isEnabled)
    }

    /// Changes the availability of sound during the call.
    /// - Parameter isEnabled: whether the sound should be enabled.
    func changeSoundState(isEnabled: Bool) async throws {
        try await webRTCClient.changeSoundState(isEnabled: isEnabled)
    }

    /// Changes the camera position (front/back) for the current user.
    /// - Parameters:
    ///  - position: the new camera position.
    func changeCameraMode(position: CameraPosition) async throws {
        try await webRTCClient.changeCameraMode(position: position)
    }

    /// Changes the speaker state.
    /// - Parameter isEnabled: whether the speaker should be enabled.
    func changeSpeakerState(isEnabled: Bool) async throws {
        try await webRTCClient.changeSpeakerState(isEnabled: isEnabled)
    }

    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCClient.changeTrackVisibility(for: participant, isVisible: isVisible)
    }

    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        webRTCClient.setVideoFilter(videoFilter)
    }

    func startScreensharing(type: ScreensharingType) async throws {
        try await webRTCClient.startScreensharing(type: type)
    }

    func stopScreensharing() async throws {
        try await webRTCClient.stopScreensharing()
    }

    /// Starts noise cancellation asynchronously.
    /// - Throws: An error if starting noise cancellation fails.
    func startNoiseCancellation(_ sessionID: String) async throws {
        try await webRTCClient.startNoiseCancellation(sessionID)
    }

    /// Stops noise cancellation asynchronously.
    /// - Throws: An error if stopping noise cancellation fails.
    func stopNoiseCancellation(_ sessionID: String) async throws {
        try await webRTCClient.stopNoiseCancellation(sessionID)
    }

    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        try await webRTCClient.changePinState(
            isEnabled: isEnabled,
            sessionId: sessionId
        )
    }

    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        await webRTCClient.updateTrackSize(trackSize, for: participant)
    }

    func updateOwnCapabilities(ownCapabilities: [OwnCapability]) {
        let oldValue = Set(webRTCClient.ownCapabilities)
        let newValue = Set(ownCapabilities)

        guard oldValue != newValue else {
            return
        }

        webRTCClient.ownCapabilities = ownCapabilities
    }

    /// Initiates a focus operation at a specific point on the camera's view.
    ///
    /// This method attempts to focus the camera at the given point by calling the `focus(at:)`
    /// method on the current WebRTC client. The focus point is specified as a `CGPoint` within the
    /// coordinate space of the view.
    ///
    /// - Parameter point: A `CGPoint` value representing the location within the view where the
    /// camera should attempt to focus. The coordinate space of the point is typically normalized to the
    /// range [0, 1], where (0, 0) represents the top-left corner of the view, and (1, 1) represents the
    /// bottom-right corner.
    /// - Throws: An error if the focus operation cannot be completed. This might occur if there is no
    /// current WebRTC client available, if the camera does not support tap to focus, or if an internal error
    /// occurs within the WebRTC client.
    ///
    /// - Note: Before calling this method, ensure that the device's camera supports tap to focus
    /// functionality and that the current WebRTC client is properly configured and connected. Otherwise,
    /// the method may throw an error.
    func focus(at point: CGPoint) throws {
        try webRTCClient.focus(at: point)
    }

    /// Adds the `AVCapturePhotoOutput` on the `CameraVideoCapturer` to enable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCapturePhotoOutput` for capturing photos. This enhancement allows applications to capture
    /// still images while video capturing is ongoing.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be added
    /// to the `CameraVideoCapturer`. This output enables the capture of photos alongside video
    /// capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support photo output functionality, an appropriate error
    /// will be thrown to indicate that the operation is not supported.
    ///
    /// - Warning: A maximum of one output of each type may be added.
    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        try webRTCClient.addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes the `AVCapturePhotoOutput` from the `CameraVideoCapturer` to disable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` by removing an
    /// `AVCapturePhotoOutput` previously added for capturing photos. This action is necessary when
    /// the application needs to stop capturing still images or when adjusting the capturing setup. It ensures
    /// that the video capturing process can continue without the overhead or interference of photo
    /// capturing capabilities.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output disables the capture of photos alongside
    /// video capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support the removal of photo output functionality, an
    /// appropriate error will be thrown to indicate that the operation is not supported.
    ///
    /// - Note: Ensure that the `AVCapturePhotoOutput` being removed was previously added to the
    /// `CameraVideoCapturer`. Attempting to remove an output that is not currently added will not
    /// affect the capture session but may result in unnecessary processing.
    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        try webRTCClient.removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Adds an `AVCaptureVideoDataOutput` to the `CameraVideoCapturer` for video frame
    /// processing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCaptureVideoDataOutput`, enabling the processing of video frames. This is particularly
    /// useful for applications that require access to raw video data for analysis, filtering, or other processing
    /// tasks while video capturing is in progress.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be added to
    /// the `CameraVideoCapturer`. This output facilitates the capture and processing of live video
    /// frames.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an
    /// `AVCaptureVideoDataOutput`. This functionality is specific to `RTCCameraVideoCapturer`
    /// instances. If the current `CameraVideoCapturer` does not accommodate video output, an error
    /// will be thrown to signify the unsupported operation.
    ///
    /// - Warning: A maximum of one output of each type may be added. For applications linked on or
    /// after iOS 16.0, this restriction no longer applies to AVCaptureVideoDataOutputs. When adding more
    /// than one AVCaptureVideoDataOutput, AVCaptureSession.hardwareCost must be taken into account.
    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        try webRTCClient.addVideoOutput(videoOutput)
    }

    /// Removes an `AVCaptureVideoDataOutput` from the `CameraVideoCapturer` to disable
    /// video frame processing capabilities.
    ///
    /// This method reconfigures the local user's `CameraVideoCapturer` by removing an
    /// `AVCaptureVideoDataOutput` that was previously added. This change is essential when the
    /// application no longer requires access to raw video data for analysis, filtering, or other processing
    /// tasks, or when adjusting the video capturing setup for different operational requirements. It ensures t
    /// hat video capturing can proceed without the additional processing overhead associated with
    /// handling video frame outputs.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output stops the capture and processing of live video
    /// frames through the specified output, simplifying the capture session.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCaptureVideoDataOutput`. This functionality is tailored for `RTCCameraVideoCapturer`
    /// instances. If the `CameraVideoCapturer` being used does not permit the removal of video outputs,
    /// an error will be thrown to indicate the unsupported operation.
    ///
    /// - Note: It is crucial to ensure that the `AVCaptureVideoDataOutput` intended for removal
    /// has been previously added to the `CameraVideoCapturer`. Trying to remove an output that is
    /// not part of the capture session will have no negative impact but could lead to unnecessary processing
    /// and confusion.
    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        try webRTCClient.removeVideoOutput(videoOutput)
    }

    /// Zooms the camera video by the specified factor.
    ///
    /// This method attempts to zoom the camera's video feed by adjusting the `videoZoomFactor` of
    /// the camera's active device. It first checks if the video capturer is of type `RTCCameraVideoCapturer`
    /// and if the current camera device supports zoom by verifying that the `videoMaxZoomFactor` of
    /// the active format is greater than 1.0. If these conditions are met, it proceeds to apply the requested
    /// zoom factor, clamping it within the supported range to avoid exceeding the device's capabilities.
    ///
    /// - Parameter factor: The desired zoom factor. A value of 1.0 represents no zoom, while values
    /// greater than 1.0 increase the zoom level. The factor is clamped to the maximum zoom factor supported
    /// by the device to ensure it remains within valid bounds.
    ///
    /// - Throws: `ClientError.Unexpected` if the video capturer is not of type
    /// `RTCCameraVideoCapturer`, or if the device does not support zoom. Also, throws an error if
    /// locking the device for configuration fails.
    ///
    /// - Note: This method should be used cautiously, as setting a zoom factor significantly beyond the
    /// optimal range can degrade video quality.
    func zoom(by factor: CGFloat) throws {
        try webRTCClient.zoom(by: factor)
    }

    /// Cleans up the call controller.
    func cleanUp() {
        guard call != nil else { return }
        call = nil
        let _webRTCClient = webRTCClient
        Task { [weak _webRTCClient] in
            await _webRTCClient?.cleanUp()
        }
    }

    /// Collects user feedback asynchronously.
    ///
    /// - Parameters:
    ///   - custom: Optional custom data in the form of a dictionary of String keys and RawJSON values.
    ///   - rating: Optional rating provided by the user.
    ///   - reason: Optional reason for the user's feedback.
    /// - Returns: An instance of `CollectUserFeedbackResponse` representing the result of collecting feedback.
    /// - Throws: An error if the feedback collection process encounters an issue.
    func collectUserFeedback(
        sessionID: String,
        custom: [String: RawJSON]? = nil,
        rating: Int? = nil,
        reason: String? = nil
    ) async throws -> CollectUserFeedbackResponse {
        try await defaultAPI.collectUserFeedback(
            type: callType,
            id: callId,
            session: sessionID,
            collectUserFeedbackRequest: .init(
                custom: custom,
                rating: rating,
                reason: reason,
                sdk: SystemEnvironment.sdkName,
                sdkVersion: SystemEnvironment.version,
                userSessionId: sessionID
            )
        )
    }

    // MARK: - private

    private func connectToEdge(
        _ response: JoinCallResponse,
        sessionID: String?,
        callType: String,
        callId: String,
        callSettings: CallSettings,
        ring: Bool,
        migratingFrom: String?
    ) async throws {
        webRTCClient.prepare(
            .connect(
                url: response.credentials.server.url,
                token: response.credentials.token,
                webSocketURL: response.credentials.server.wsEndpoint,
                ownCapabilities: response.ownCapabilities,
                audioSettings: response.call.settings.audio
            )
        )

        let videoOptions = VideoOptions(
            targetResolution: response.call.settings.video.targetResolution
        )
        let connectOptions = ConnectOptions(
            iceServers: response.credentials.iceServers
        )

        try await webRTCClient.connect(
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }

    private func handleParticipantsUpdated() {
        webRTCClient.onParticipantsUpdated = { [weak self] participants in
            DispatchQueue.main.async {
                self?.call?.state.participantsMap = participants
            }
        }
    }

    private func handleParticipantCountUpdated() {
        webRTCClient.onParticipantCountUpdated = { [weak self] participantCount in
            DispatchQueue.main.async {
                self?.call?.state.participantCount = participantCount
            }
        }
    }

    private func joinCall(
        create: Bool,
        callType: String,
        callId: String,
        options: CreateCallOptions? = nil,
        migratingFrom: String?,
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        let location = try await getLocation()
        let response = try await joinCall(
            callId: callId,
            type: callType,
            location: location,
            options: options,
            migratingFrom: migratingFrom,
            create: create,
            ring: ring,
            notify: notify
        )
        return response
    }

    private func authenticateCall(create: Bool) async throws -> JoinCallResponse {
        let response = try await joinCall(
            create: create,
            callType: callType,
            callId: callId,
            options: nil,
            migratingFrom: currentSFU,
            ring: false,
            notify: false
        )

        // We allow the CallController to manage its state.
        joinCallResponseSubject.send(response)

        return response
    }

    private func prefetchLocation() {
        Task {
            do {
                self.cachedLocation = try await getLocation()
            } catch {
                log.error(error)
            }
        }
    }

    private func getLocation() async throws -> String {
        if let cachedLocation {
            return cachedLocation
        }
        return try await LocationFetcher.getLocation()
    }

    private func joinCall(
        callId: String,
        type: String,
        location: String,
        options: CreateCallOptions? = nil,
        migratingFrom: String?,
        create: Bool,
        ring: Bool,
        notify: Bool
    ) async throws -> JoinCallResponse {
        var membersRequest = [MemberRequest]()
        options?.memberIds?.forEach {
            membersRequest.append(.init(userId: $0))
        }
        options?.members?.forEach {
            membersRequest.append($0)
        }
        let callRequest = CallRequest(
            custom: options?.custom,
            members: membersRequest,
            settingsOverride: options?.settings,
            startsAt: options?.startsAt,
            team: options?.team
        )
        let joinCall = JoinCallRequest(
            create: create,
            data: callRequest,
            location: location,
            migratingFrom: migratingFrom,
            notify: notify,
            ring: ring
        )
        let joinCallResponse = try await defaultAPI.joinCall(
            type: type,
            id: callId,
            joinCallRequest: joinCall
        )
        return joinCallResponse
    }

    private func didFetch(_ response: JoinCallResponse) {
        let sessionId = webRTCClient.sessionID
        currentSFU = response.credentials.server.edgeName
        webRTCClient.statsReporter.interval = TimeInterval(response.statsOptions.reportingIntervalMs / 1000)
        executeOnMain { [weak self] in
            self?.call?.state.sessionId = sessionId
            self?.call?.update(recordingState: response.call.recording ? .recording : .noRecording)
            self?.call?.state.ownCapabilities = response.ownCapabilities
            self?.call?.state.update(from: response)
        }
    }
}

extension CallController {
    struct Environment {
        var webRTCBuilder: (
            _ user: User,
            _ apiKey: String,
            _ callCid: String,
            _ videoConfig: VideoConfig,
            _ environment: WebSocketClient.Environment,
            _ callAuthenticator: CallAuthenticating
        ) -> WebRTCClient = {
            WebRTCClient(
                user: $0,
                apiKey: $1,
                callCid: $2,
                videoConfig: $3,
                environment: $4,
                callAuthenticator: $5
            )
        }

        var sfuReconnectionTime: CGFloat = 30
    }
}

extension CallController: WebRTCClientDelegate {

    func webRTCClientMigrating() {
        log.debug(#function)
        call?.update(reconnectionStatus: .migrating)
    }

    func webRTCClientMigrated() {
        log.debug(#function)
        call?.update(reconnectionStatus: .connected)
    }

    func webRTCClientDisconnected() {
        log.debug(#function)
        call?.update(reconnectionStatus: .disconnected)
//        cleanUp()
    }

    func webRTCClientReconnecting() {
        log.debug(#function)
        call?.update(reconnectionStatus: .reconnecting)
    }

    func webRTCClientConnected() {
        log.debug(#function)
        log.debug("Signal channel connected")
        if reconnectionDate != nil {
            reconnectionDate = nil
        }
        executeOnMain { [weak self] in
            guard let self else { return }
            let status = self.call?.state.reconnectionStatus
            if status != .migrating {
                self.call?.update(reconnectionStatus: .connected)
            }
        }
    }
}
