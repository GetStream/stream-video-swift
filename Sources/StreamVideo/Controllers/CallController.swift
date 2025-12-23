//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Class that handles a particular call.
class CallController: @unchecked Sendable {
    private enum DisposableKey: String {
        case participantsCountUpdatesEvent
        case currentUserBlocked
    }

    private lazy var webRTCCoordinator = webRTCCoordinatorFactory.buildCoordinator(
        user: user,
        apiKey: apiKey,
        callCid: callCid(from: callId, callType: callType),
        videoConfig: videoConfig
    ) {
        [weak self, callId] create, ring, migratingFrom, notify, options in
        if let self {
            return try await authenticateCall(
                create: create,
                ring: ring,
                migratingFrom: migratingFrom,
                notify: notify,
                options: options
            )
        } else {
            throw ClientError("Unable to authenticate callId:\(callId).")
        }
    }

    weak var call: Call? {
        didSet {
            subscribeToParticipantsCountUpdatesEvent(call)
            subscribeToCurrentUserBlockedState(call)
            if let call {
                Task(disposableBag: disposableBag) { @MainActor [weak self] in
                    guard let self else { return }
                    call.state.sessionId = await webRTCCoordinator.stateAdapter.sessionID
                }
            }
        }
    }

    private let user: User
    private let callId: String
    private let callType: String
    private let apiKey: String
    private let defaultAPI: DefaultAPIEndpoints
    private let videoConfig: VideoConfig
    private let webRTCCoordinatorFactory: WebRTCCoordinatorProviding
    private var cachedLocation: String?

    private var joinCallResponseSubject = CurrentValueSubject<JoinCallResponse?, Error>(nil)
    private var joinCallResponseFetchObserver: AnyCancellable?
    private var webRTCClientSessionIDObserver: AnyCancellable?
    private var webRTCClientStateObserver: AnyCancellable?
    private var webRTCParticipantsObserver: AnyCancellable?
    private var participants: CollectionDelayedUpdateObserver<[String: CallParticipant]>?

    private let disposableBag = DisposableBag()

    init(
        defaultAPI: DefaultAPIEndpoints,
        user: User,
        callId: String,
        callType: String,
        apiKey: String,
        videoConfig: VideoConfig,
        cachedLocation: String?,
        webRTCCoordinatorFactory: WebRTCCoordinatorProviding = WebRTCCoordinatorFactory()
    ) {
        self.user = user
        self.callId = callId
        self.callType = callType
        self.apiKey = apiKey
        self.videoConfig = videoConfig
        self.defaultAPI = defaultAPI
        self.cachedLocation = cachedLocation
        self.webRTCCoordinatorFactory = webRTCCoordinatorFactory

        _ = webRTCCoordinator

        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            await handleParticipantCountUpdated()
            let participantsPublisher = await webRTCCoordinator.stateAdapter.$participants
            participants = CollectionDelayedUpdateObserver(
                publisher: participantsPublisher.eraseToAnyPublisher(),
                initial: [:],
                mode: .throttle(scheduler: DispatchQueue.main, latest: true)
            )
            handleParticipantsUpdated()
            await observeSessionIDUpdates()
            await observeStatsReporterUpdates()
            await observeCallSettingsUpdates()
        }

        joinCallResponseFetchObserver = joinCallResponseSubject
            .compactMap { $0 }
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didFetch($0) }
    }

    /// Joins a call with the provided information and join source.
    ///
    /// - Parameters:
    ///   - callType: The type of the call.
    ///   - callId: The id of the call.
    ///   - callSettings: The current call settings.
    ///   - videoOptions: Configuration options about the video.
    ///   - options: Create call options.
    ///   - migratingFrom: If SFU migration is being performed.
    ///   - ring: Whether ringing events should be handled.
    ///   - notify: Whether users should be notified about the call.
    ///   - source: Describes the source from which the join action was triggered.
    ///            Use this to indicate if the call was joined from in-app UI or
    ///            via CallKit.
    /// - Returns: A newly created `JoinCallResponse`.
    @discardableResult
    func joinCall(
        create: Bool = true,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        source: JoinSource
    ) async throws -> JoinCallResponse {
        joinCallResponseSubject = .init(nil)

        try await webRTCCoordinator.connect(
            create: create,
            callSettings: callSettings,
            options: options,
            ring: ring,
            notify: notify,
            source: source
        )
        
        guard
            let response = try await joinCallResponseSubject
            .nextValue(dropFirst: 1, timeout: WebRTCConfiguration.timeout.join)
        else {
            await webRTCCoordinator.cleanUp()
            throw ClientError("Unable to connect to call callId:\(callId).")
        }
        return response
    }

    /// Changes the audio state for the current user.
    /// - Parameter isEnabled: whether audio should be enabled.
    func changeAudioState(
        isEnabled: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        await webRTCCoordinator.changeAudioState(
            isEnabled: isEnabled,
            file: file,
            function: function,
            line: line
        )
    }

    /// Changes the video state for the current user.
    /// - Parameter isEnabled: whether video should be enabled.
    func changeVideoState(isEnabled: Bool) async throws {
        await webRTCCoordinator.changeVideoState(isEnabled: isEnabled)
    }

    /// Changes the availability of sound during the call.
    /// - Parameter isEnabled: whether the sound should be enabled.
    func changeSoundState(isEnabled: Bool) async throws {
        await webRTCCoordinator.changeSoundState(isEnabled: isEnabled)
    }

    /// Changes the camera position (front/back) for the current user.
    /// - Parameters:
    ///  - position: the new camera position.
    func changeCameraMode(position: CameraPosition) async throws {
        try await webRTCCoordinator.changeCameraMode(position: position)
    }

    /// Changes the speaker state.
    /// - Parameter isEnabled: whether the speaker should be enabled.
    func changeSpeakerState(isEnabled: Bool) async throws {
        await webRTCCoordinator.changeSpeakerState(isEnabled: isEnabled)
    }

    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) async {
        await webRTCCoordinator.changeTrackVisibility(
            for: participant,
            isVisible: isVisible
        )
    }

    /// Sets a `videoFilter` for the current call.
    /// - Parameter videoFilter: A `VideoFilter` instance representing the video filter to set.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            await webRTCCoordinator.setVideoFilter(videoFilter)
        }
    }

    /// Starts screensharing for the current call.
    /// - Parameters:
    ///   - type: The screensharing type (in-app or broadcasting).
    ///   - includeAudio: Whether to capture app audio during screensharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    func startScreensharing(
        type: ScreensharingType,
        includeAudio: Bool
    ) async throws {
        try await webRTCCoordinator.startScreensharing(
            type: type,
            includeAudio: includeAudio
        )
    }

    func stopScreensharing() async throws {
        try await webRTCCoordinator.stopScreensharing()
    }

    /// Starts noise cancellation asynchronously.
    /// - Throws: An error if starting noise cancellation fails.
    func startNoiseCancellation(_ sessionID: String) async throws {
        try await webRTCCoordinator.startNoiseCancellation(sessionID)
    }

    /// Stops noise cancellation asynchronously.
    /// - Throws: An error if stopping noise cancellation fails.
    func stopNoiseCancellation(_ sessionID: String) async throws {
        try await webRTCCoordinator.stopNoiseCancellation(sessionID)
    }

    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        try await webRTCCoordinator.changePinState(
            isEnabled: isEnabled,
            sessionId: sessionId
        )
    }

    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) async {
        guard participant.trackSize != trackSize else { return }
        await webRTCCoordinator.updateTrackSize(trackSize, for: participant)
    }

    func updateOwnCapabilities(ownCapabilities: [OwnCapability]) async {
        let oldValue = await webRTCCoordinator.stateAdapter.ownCapabilities
        let newValue = Set(ownCapabilities)

        guard oldValue != newValue else {
            return
        }

        await webRTCCoordinator.stateAdapter.set(ownCapabilities: .init(ownCapabilities))
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
    func focus(at point: CGPoint) async throws {
        try await webRTCCoordinator.focus(at: point)
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
    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) async throws {
        try await webRTCCoordinator.addCapturePhotoOutput(capturePhotoOutput)
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
    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) async throws {
        try await webRTCCoordinator.removeCapturePhotoOutput(capturePhotoOutput)
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
    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) async throws {
        try await webRTCCoordinator.addVideoOutput(videoOutput)
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
    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) async throws {
        try await webRTCCoordinator.removeVideoOutput(videoOutput)
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
    func zoom(by factor: CGFloat) async throws {
        try await webRTCCoordinator.zoom(by: factor)
    }

    func leave() {
        guard call != nil else { return }
        call = nil
        webRTCCoordinator.leave()
    }

    /// Cleans up the call controller.
    func cleanUp() {
        guard call != nil else { return }
        call = nil
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            await webRTCCoordinator.cleanUp()
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
        custom: [String: RawJSON]? = nil,
        rating: Int,
        reason: String? = nil
    ) async throws -> CollectUserFeedbackResponse {
        try await defaultAPI.collectUserFeedback(
            type: callType,
            id: callId,
            collectUserFeedbackRequest: .init(
                custom: custom,
                rating: rating,
                reason: reason,
                sdk: SystemEnvironment.sdkName,
                sdkVersion: SystemEnvironment.version
            )
        )
    }

    // MARK: - Incoming video policy

    /// Sets the incoming video policy. This function updates the state and informs the coordinator
    /// about the new video policy asynchronously.
    ///
    /// - Parameter value: The new `setIncomingVideoQualitySettings` to be applied. It determines
    ///   whether video streams are allowed, manually controlled, or disabled for
    ///   specific session groups.
    func setIncomingVideoQualitySettings(
        _ value: IncomingVideoQualitySettings
    ) async {
        await webRTCCoordinator.setIncomingVideoQualitySettings(value)
    }

    // MARK: - Disconnection timeout

    /// Sets the disconnection timeout for the current call.
    ///
    /// The timeout defines how long a user can stay disconnected
    /// before being dropped from the call.
    ///
    /// - Parameter timeout: The time interval to set as the timeout.
    func setDisconnectionTimeout(_ timeout: TimeInterval) {
        webRTCCoordinator.setDisconnectionTimeout(timeout)
    }

    // MARK: - Codec preference

    /// Updates video publishing options with the preferred video codec and max bitrate for video
    /// streaming.
    ///
    /// - Parameters:
    ///    - preferredVideoCodec: The preferred video codec (e.g., H264, VP8, VP9, AV1).
    ///    - maxBitrate: The maximum allowed bitrate for video streaming.
    func updatePublishOptions(
        preferredVideoCodec: VideoCodec,
        maxBitrate: Int
    ) async {
        await webRTCCoordinator.updatePublishOptions(
            preferredVideoCodec: preferredVideoCodec,
            maxBitrate: maxBitrate
        )
    }

    /// Updates the audio session policy for the WebRTC coordinator.
    ///
    /// This function configures how the audio session behaves during calls,
    /// such as mixing with other audio or interrupting other audio sources.
    ///
    /// - Parameter policy: The audio session policy to apply
    /// - Throws: An error if the policy update fails
    func updateAudioSessionPolicy(_ policy: AudioSessionPolicy) async {
        await webRTCCoordinator.updateAudioSessionPolicy(policy)
    }

    /// Sets up observation of WebRTC state changes.
    ///
    /// This function establishes a subscription to the WebRTC coordinator's
    /// state machine to monitor connection status changes. The observer
    /// will be notified on the main queue when the WebRTC state changes.
    func observeWebRTCStateUpdated() {
        guard webRTCClientStateObserver == nil else {
            return
        }
        
        webRTCClientStateObserver = webRTCCoordinator
            .stateMachine
            .publisher
            .log(.debug) { "WebRTC stack connection status updated to \($0.id)." }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.webRTCClientDidUpdateStage($0) }
    }

    // MARK: - Client Capabilities

    func enableClientCapabilities(_ capabilities: Set<ClientCapability>) async {
        await webRTCCoordinator.enableClientCapabilities(capabilities)
    }

    func disableClientCapabilities(_ capabilities: Set<ClientCapability>) async {
        await webRTCCoordinator.disableClientCapabilities(capabilities)
    }

    // MARK: - CallKit tracing

    func didPerform(_ action: WebRTCTrace.CallKitAction) async {
        await webRTCCoordinator.didPerform(action)
    }

    // MARK: - private

    private func handleParticipantsUpdated() {
        webRTCParticipantsObserver = participants?
            .$value
            .removeDuplicates() // Avoid unnecessary updates when participants haven't changed.
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] participants in
                self?.call?.state.participantsMap = participants
            }
    }

    private func handleParticipantCountUpdated() async {
        await webRTCCoordinator
            .stateAdapter
            .$participantsCount
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.call?.state.participantCount = $0 }
            .store(in: disposableBag)

        await webRTCCoordinator
            .stateAdapter
            .$anonymousCount
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.call?.state.anonymousParticipantCount = $0 }
            .store(in: disposableBag)
    }

    private func authenticateCall(
        create: Bool,
        ring: Bool,
        migratingFrom: String?,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> JoinCallResponse {
        do {
            let location = try await getLocation()
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
            let response = try await defaultAPI.joinCall(
                type: callType,
                id: callId,
                joinCallRequest: joinCall
            )
            
            // We allow the CallController to manage its state.
            joinCallResponseSubject.send(response)
            
            return response
        } catch {
            joinCallResponseSubject.send(completion: .failure(error))
            throw error
        }
    }

    private func prefetchLocation() {
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
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

    private func didFetch(_ response: JoinCallResponse) async {
        let sessionId = await webRTCCoordinator.stateAdapter.sessionID
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            self?.call?.state.sessionId = sessionId
            self?.call?.update(recordingState: response.call.recording ? .recording : .noRecording)
            self?.call?.state.ownCapabilities = response.ownCapabilities
            self?.call?.state.update(from: response)
        }
    }

    private func webRTCClientDidUpdateStage(
        _ stage: WebRTCCoordinator.StateMachine.Stage
    ) {
        switch stage.id {
        case .idle:
            call?.update(reconnectionStatus: .disconnected)
        case .rejoining:
            call?.update(reconnectionStatus: .reconnecting)
        case .migrating:
            call?.update(reconnectionStatus: .migrating)
        case .leaving:
            call?.leave()
        case .joined:
            /// Once connected we should stop listening for CallSessionParticipantCountsUpdatedEvent
            /// updates and only rely on the healthCheck event.
            disposableBag.remove(DisposableKey.participantsCountUpdatesEvent.rawValue)

            call?.update(reconnectionStatus: .connected)
        case .error:
            Task(disposableBag: disposableBag) { @MainActor [weak self] in
                guard let self else { return }
                if let call, let errorStage = stage as? WebRTCCoordinator.StateMachine.Stage.ErrorStage {
                    call.transitionDueToError(errorStage.error)
                }
                call?.leave()
            }
        default:
            break
        }
    }

    private func subscribeToParticipantsCountUpdatesEvent(_ call: Call?) {
        disposableBag.remove(DisposableKey.participantsCountUpdatesEvent.rawValue)

        guard let call else { return }

        let anonymousUserRoleKey = "anonymous"

        call
            .eventPublisher(for: CallSessionParticipantCountsUpdatedEvent.self)
            .sinkTask(storeIn: disposableBag) { @MainActor [weak call] event in
                call?.state.participantCount = event
                    .participantsCountByRole
                    .filter { $0.key != anonymousUserRoleKey } // TODO: Workaround. To be removed
                    .values
                    .map(UInt32.init)
                    .reduce(0) { $0 + $1 }

                // TODO: Workaround. To be removed
                if event.anonymousParticipantCount > 0 {
                    call?.state.anonymousParticipantCount = UInt32(event.anonymousParticipantCount)
                } else if let anonymousCount = event.participantsCountByRole[anonymousUserRoleKey] {
                    call?.state.anonymousParticipantCount = UInt32(anonymousCount)
                } else {
                    call?.state.anonymousParticipantCount = 0
                }
            }
            .store(in: disposableBag, key: DisposableKey.participantsCountUpdatesEvent.rawValue)
    }

    private func subscribeToCurrentUserBlockedState(_ call: Call?) {
        disposableBag.remove(DisposableKey.currentUserBlocked.rawValue)
        guard let call else { return }
        let currentUser = user
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else {
                return
            }

            call
                .state
                .$blockedUserIds
                .filter { $0.contains(currentUser.id) }
                .log(.debug, subsystems: .webRTC) { _ in "Current user was blocked. Will leave the call now." }
                .sinkTask(storeIn: disposableBag) { [weak self] _ in
                    guard let self else { return }
                    self
                        .webRTCCoordinator
                        .stateMachine
                        .transition(.blocked(self.webRTCCoordinator.stateMachine.currentStage.context))
                }
                .store(in: disposableBag, key: DisposableKey.currentUserBlocked.rawValue)
        }
    }

    private func observeSessionIDUpdates() async {
        webRTCClientSessionIDObserver = await webRTCCoordinator
            .stateAdapter
            .$sessionID
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.call?.state.sessionId = $0 }
    }

    private func observeStatsReporterUpdates() async {
        await webRTCCoordinator
            .stateAdapter
            .$statsAdapter
            .compactMap { $0 }
            .sink { [disposableBag, weak self] statsReporter in
                statsReporter
                    .latestReportPublisher
                    .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.call?.state.statsReport = $0 }
                    .store(in: disposableBag)
            }
            .store(in: disposableBag)
    }

    private func observeCallSettingsUpdates() async {
        await webRTCCoordinator
            .stateAdapter
            .$callSettings
            .removeDuplicates()
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.call?.state.callSettings = $0 }
            .store(in: disposableBag)
    }
}
