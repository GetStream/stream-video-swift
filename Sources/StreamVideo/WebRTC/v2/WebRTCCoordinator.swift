//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A coordinator that manages WebRTC connections, state transitions, and media
/// operations. It interacts with a state machine to handle different WebRTC
/// stages and uses adapters to handle the media-related functionalities.
final class WebRTCCoordinator: @unchecked Sendable {

    /// A typealias for a closure that handles authentication for joining a call.
    /// - Parameters:
    ///   - create: Whether the call should be created on the backend side.
    ///   - ring: Whether the call is a ringing call.
    ///   - migratingFrom: If migrating, where are we migrating from.
    ///   - notify:
    ///   - options:
    /// - Returns: A `JoinCallResponse` wrapped in an async throw.
    typealias AuthenticationHandler = (
        Bool,
        Bool,
        String?,
        Bool,
        CreateCallOptions?
    ) async throws -> JoinCallResponse

    private static let recordingUserId = "recording-egress"
    private static let participantsThreshold = 10

    /// The state adapter manages the WebRTC state and media configuration.
    let stateAdapter: WebRTCStateAdapter

    /// The handler used for authenticating the user during call joining.
    let callAuthentication: AuthenticationHandler

    /// The state machine that manages the different stages of the WebRTC
    /// lifecycle.
    private(set) lazy var stateMachine: StateMachine = .init(.init(coordinator: self))

    private let disposableBag = DisposableBag()

    /// Initializes the `WebRTCCoordinator` with user details, video settings,
    /// and connection handlers.
    ///
    /// - Parameters:
    ///   - user: The current user participating in the call.
    ///   - apiKey: The API key to authenticate with the WebRTC service.
    ///   - callCid: The call identifier (cid).
    ///   - videoConfig: The video configuration for the call.
    ///   - webRTCAuthenticator: The authenticator that will be used during all WebRTC flows.
    ///   - callAuthentication: A closure for handling call authentication.
    ///   - rtcPeerConnectionCoordinatorFactory: Factory for creating the peer
    ///     connection coordinator.
    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding = StreamRTCPeerConnectionCoordinatorFactory(),
        webRTCAuthenticator: WebRTCAuthenticating = WebRTCAuthenticator(),
        callAuthentication: @escaping AuthenticationHandler
    ) {
        stateAdapter = .init(
            user: user,
            apiKey: apiKey,
            callCid: callCid,
            videoConfig: videoConfig,
            rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory
        )
        self.callAuthentication = callAuthentication

        // Initialize the state machine.
        stateMachine.currentStage.context.authenticator = webRTCAuthenticator

        #if OBSERVE_RECONNECTION_NOTIFICATIONS
        observeForceReconnectionRequests()
        #endif
    }

    // MARK: - Connection

    /// Connects to a call with the specified settings and whether to ring.
    ///
    /// - Parameters:
    ///   - callSettings: Optional call settings.
    ///   - ring: Boolean flag indicating if a ring tone should be played.
    func connect(
        create: Bool = true,
        callSettings: CallSettings?,
        options: CreateCallOptions?,
        ring: Bool,
        notify: Bool,
        source: JoinSource
    ) async throws {
        await stateAdapter.set(initialCallSettings: callSettings)
        stateMachine.currentStage.context.joinSource = source
        stateMachine.transition(
            .connecting(
                stateMachine.currentStage.context,
                create: create,
                options: options,
                ring: ring,
                notify: notify
            )
        )
    }

    /// Cleans up the state adapter resources after a call ends.
    func cleanUp() async {
        await stateAdapter.cleanUp()
    }

    /// Leaves the call and transitions the state machine to the `leaving` stage.
    func leave() {
        stateMachine.transition(
            .leaving(stateMachine.currentStage.context)
        )
    }

    // MARK: - Media

    /// Changes the camera position between front and back.
    ///
    /// - Parameter position: The desired camera position.
    func changeCameraMode(
        position: CameraPosition
    ) async throws {
        await stateAdapter
            .enqueueCallSettings { $0.withUpdatedCameraPosition(position) }
    }

    /// Changes the audio state (enabled/disabled) for the call.
    ///
    /// - Parameter isEnabled: Whether the audio should be enabled.
    func changeAudioState(
        isEnabled: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async {
        await stateAdapter
            .enqueueCallSettings(
                functionName: function,
                fileName: file,
                lineNumber: line
            ) {
                $0.withUpdatedAudioState(
                    isEnabled,
                    file: file,
                    function: function,
                    line: line
                )
            }
    }

    /// Changes the video state (enabled/disabled) for the call.
    ///
    /// - Parameter isEnabled: Whether the video should be enabled.
    func changeVideoState(isEnabled: Bool) async {
        await stateAdapter
            .enqueueCallSettings { $0.withUpdatedVideoState(isEnabled) }
    }

    /// Changes the audio output state (e.g., speaker or headphones).
    ///
    /// - Parameter isEnabled: Whether the output should be enabled.
    func changeSoundState(isEnabled: Bool) async {
        await stateAdapter
            .enqueueCallSettings { $0.withUpdatedAudioOutputState(isEnabled) }
    }

    /// Changes the speaker state (enabled/disabled) for the call.
    ///
    /// - Parameter isEnabled: Whether the speaker should be enabled.
    func changeSpeakerState(isEnabled: Bool) async {
        await stateAdapter
            .enqueueCallSettings { $0.withUpdatedSpeakerState(isEnabled) }
    }

    /// Updates the visibility of a participant's track.
    ///
    /// - Parameters:
    ///   - participant: The participant whose track's visibility is to be updated.
    ///   - isVisible: Boolean flag indicating if the track should be visible.
    func changeTrackVisibility(
        for participant: CallParticipant,
        isVisible: Bool
    ) async {
        await stateAdapter.enqueue { participants in
            guard
                let participant = participants[participant.id],
                participant.showTrack != isVisible
            else {
                return participants
            }
            var updatedParticipants = participants
            updatedParticipants[participant.id] = participant
                .withUpdated(showTrack: isVisible)
            return updatedParticipants
        }
    }

    /// Updates the track size for a participant.
    ///
    /// - Parameters:
    ///   - trackSize: The new size of the video track.
    ///   - participant: The participant whose track's size is being updated.
    func updateTrackSize(
        _ trackSize: CGSize,
        for participant: CallParticipant
    ) async {
        await stateAdapter.enqueue { participants in
            guard
                let participant = participants[participant.id],
                participant.trackSize != trackSize
            else {
                return participants
            }
            var updatedParticipants = participants
            updatedParticipants[participant.id] = participant
                .withUpdated(trackSize: trackSize)
            return updatedParticipants
        }
    }

    /// Sets a video filter for the call.
    ///
    /// - Parameter videoFilter: The filter to be applied on the video.
    func setVideoFilter(_ videoFilter: VideoFilter?) async {
        await stateAdapter.set(videoFilter: videoFilter)
    }

    // MARK: - Screensharing

    /// Starts screensharing of the specified type.
    ///
    /// - Parameters:
    ///   - type: The type of screensharing.
    ///   - includeAudio: Whether to capture app audio during screensharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    func startScreensharing(
        type: ScreensharingType,
        includeAudio: Bool
    ) async throws {
        try await stateAdapter.publisher?.beginScreenSharing(
            of: type,
            ownCapabilities: Array(stateAdapter.ownCapabilities),
            includeAudio: includeAudio
        )
    }

    /// Stops screensharing.
    func stopScreensharing() async throws {
        try await stateAdapter.publisher?.stopScreenSharing()
    }

    /// Changes the pin state of a participant.
    ///
    /// - Parameters:
    ///   - isEnabled: Boolean flag indicating if pinning is enabled.
    ///   - sessionId: The session ID of the participant to pin.
    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        await stateAdapter.enqueue { participants in
            guard
                let participant = participants[sessionId]
            else {
                return participants
            }
            var updatedParticipants = participants
            let pin = isEnabled ? PinInfo(isLocal: true, pinnedAt: Date()) : nil
            updatedParticipants[participant.id] = participant.withUpdated(pin: pin)
            return updatedParticipants
        }
    }

    /// Starts noise cancellation for a participant's session.
    ///
    /// - Parameter sessionID: The session ID to apply noise cancellation to.
    func startNoiseCancellation(
        _ sessionID: String
    ) async throws {
        try await stateAdapter
            .sfuAdapter?
            .toggleNoiseCancellation(true, for: sessionID)
    }

    /// Stops noise cancellation for a participant's session.
    ///
    /// - Parameter sessionID: The session ID to disable noise cancellation for.
    func stopNoiseCancellation(
        _ sessionID: String
    ) async throws {
        try await stateAdapter
            .sfuAdapter?
            .toggleNoiseCancellation(false, for: sessionID)
    }

    /// Focuses on a specific point in the video.
    ///
    /// - Parameter point: The point at which to focus.
    func focus(at point: CGPoint) async throws {
        try await stateAdapter.publisher?.focus(at: point)
    }

    /// Adds a photo output to the capture session.
    ///
    /// - Parameter capturePhotoOutput: The capture output for photo capturing.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    /// Removes a photo output from the capture session.
    ///
    /// - Parameter capturePhotoOutput: The capture output for photo capturing.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    /// Adds a video output to the capture session.
    ///
    /// - Parameter videoOutput: The capture output for video capturing.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .addVideoOutput(videoOutput)
    }

    /// Removes a video output from the capture session.
    ///
    /// - Parameter videoOutput: The capture output for video capturing.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .removeVideoOutput(videoOutput)
    }

    /// Zooms the camera by a specified factor.
    ///
    /// - Parameter factor: The zoom factor to apply.
    func zoom(by factor: CGFloat) async throws {
        try await stateAdapter
            .publisher?
            .zoom(by: factor)
    }

    // MARK: - Incoming video policy

    /// Sets the incoming video quality settings. This function updates the state with the new policy. This
    /// change is then triggering an update in the policy observation (in JoinedStage).
    ///
    /// - Parameter value: The new `IncomingVideoQualitySettings` to be applied. It
    /// determines whether video streams are allowed, manually controlled, or disabled for
    /// specific session groups.
    func setIncomingVideoQualitySettings(
        _ value: IncomingVideoQualitySettings
    ) async {
        await stateAdapter.set(incomingVideoQualitySettings: value)
    }

    // MARK: - Disconnection timeout

    /// Sets the disconnection timeout for the current call.
    ///
    /// Updates the disconnection timeout in the state machine's context.
    /// The timeout defines how long a user can stay disconnected
    /// before being dropped from the call.
    ///
    /// - Parameter timeout: The time interval to set as the timeout.
    func setDisconnectionTimeout(_ timeout: TimeInterval) {
        stateMachine.currentStage.context.disconnectionTimeout = timeout
        log.debug("Disconnection timeout was set to \(timeout).")
    }

    // MARK: - Codec preference

    /// Updates video publishing options asynchronously.
    ///
    /// Updates the preferred video codec and max bitrate for video streaming by
    /// modifying the current video options and applying them via the state
    /// adapter.
    ///
    /// - Parameters:
    ///    - preferredVideoCodec: The preferred video codec (e.g., H264, VP8, VP9, AV1).
    ///    - maxBitrate: The maximum allowed bitrate for video streaming.
    func updatePublishOptions(
        preferredVideoCodec: VideoCodec,
        maxBitrate: Int
    ) async {
        // For the request videoCodec, we query WebRTC to get the best
        // fmtp to use.
        let fmtp = stateAdapter
            .peerConnectionFactory
            .codecCapabilities(for: preferredVideoCodec)?.fmtp ?? ""

        if fmtp.isEmpty {
            log.warning(
                "Unable to detect fmtp for video codec:\(preferredVideoCodec).",
                subsystems: .webRTC
            )
        }

        await stateAdapter.set(
            publishOptions: PublishOptions(
                video: [
                    .init(
                        codec: preferredVideoCodec,
                        fmtp: fmtp,
                        bitrate: maxBitrate
                    )
                ]
            )
        )
    }

    func updateAudioSessionPolicy(_ policy: AudioSessionPolicy) async {
        await stateAdapter.set(audioSessionPolicy: policy)
    }

    func enableClientCapabilities(_ capabilities: Set<ClientCapability>) async {
        await stateAdapter.enableClientCapabilities(capabilities)
    }

    func disableClientCapabilities(_ capabilities: Set<ClientCapability>) async {
        await stateAdapter.disableClientCapabilities(capabilities)
    }

    // MARK: - CallKit tracing

    func didPerform(_ action: WebRTCTrace.CallKitAction) async {
        await stateAdapter.trace(.init(action))
    }

    // MARK: - Private

    /// Creates the state machine for managing WebRTC stages.
    ///
    /// - Returns: The newly created state machine.
    private func makeStateMachine() async -> WebRTCCoordinator.StateMachine {
        .init(.init(coordinator: self))
    }

    #if OBSERVE_RECONNECTION_NOTIFICATIONS
    /// Observes notifications for forced reconnection requests and transitions
    /// the state machine accordingly.
    private func observeForceReconnectionRequests() {
        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.fast"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .fast(
                    disconnectedSince: .init(),
                    deadline: stateMachine.currentStage.context.fastReconnectDeadlineSeconds
                )
                stateMachine.transition(
                    .disconnected(stateMachine.currentStage.context)
                )
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.rejoin"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .rejoin
                stateMachine.transition(
                    .disconnected(stateMachine.currentStage.context)
                )
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.migrate"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .migrate
                stateMachine.transition(
                    .disconnected(stateMachine.currentStage.context)
                )
            }
            .store(in: disposableBag)
    }
    #endif
}
