//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
@preconcurrency import XCTest

final class CallController_Tests: StreamVideoTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var defaultAPI: DefaultAPI! = DefaultAPI(
        basePath: "example.com",
        transport: httpClient,
        middlewares: []
    )
    private lazy var user: User! = .dummy()
    private lazy var callId: String! = .unique
    private lazy var callType: String! = .default
    private lazy var apiKey: String! = .unique
    private lazy var initialCallSettings: CallSettings! = .default
    private lazy var cachedLocation: String? = .unique
    private lazy var mockWebRTCCoordinatorFactory: MockWebRTCCoordinatorFactory! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: CallController! = .init(
        defaultAPI: defaultAPI,
        user: user,
        callId: callId,
        callType: callType,
        apiKey: apiKey,
        videoConfig: Self.videoConfig,
        initialCallSettings: initialCallSettings,
        cachedLocation: cachedLocation,
        webRTCCoordinatorFactory: mockWebRTCCoordinatorFactory
    )

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        _ = mockPermissions
    }

    override func tearDown() {
        mockPermissions.dismantle()

        subject = nil
        mockWebRTCCoordinatorFactory = nil
        cachedLocation = nil
        apiKey = nil
        initialCallSettings = nil
        callType = nil
        callId = nil
        user = nil
        defaultAPI = nil
        httpClient = nil
        mockPermissions = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_propagatesInitialCallSettingsToWebRTCCoordinator() {
        let callSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            cameraPosition: .back
        )
        self.initialCallSettings = callSettings

        _ = subject

        XCTAssertEqual(
            mockWebRTCCoordinatorFactory.buildCoordinatorWasCalled?.callSettings,
            callSettings
        )
    }

    // MARK: - setCall

    func test_setCall_updatesSessionIdCorrectly() async throws {
        let call = await MockCall(.dummy())
        _ = subject
        subject.call = call

        await fulfilmentInMainActor { call.state.sessionId.isEmpty == false }
    }

    // MARK: - joinCall

    func test_joinCall_coordinatorTransitionsToConnecting() async throws {
        let callSettings = CallSettings(cameraPosition: .back)
        let options = CreateCallOptions(team: .unique)

        try await assertTransitionToStage(
            .connecting,
            operation: {
                /// We are wrapping in a task as we are not interested in the call result.
                Task {
                    try? await self
                        .subject
                        .joinCall(
                            create: true,
                            callSettings: callSettings,
                            options: options,
                            ring: true,
                            notify: true,
                            source: .callKit
                        )
                }
            }
        ) { stage in
            let expectedStage = try XCTUnwrap(stage as? WebRTCCoordinator.StateMachine.Stage.ConnectingStage)
            XCTAssertEqual(expectedStage.options?.team, options.team)
            XCTAssertTrue(expectedStage.ring)
            XCTAssertTrue(expectedStage.notify)
            XCTAssertEqual(expectedStage.context.joinSource, .callKit)
            await self.assertEqualAsync(
                await self
                    .mockWebRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .coordinator
                    .stateAdapter
                    .initialCallSettings,
                callSettings
            )
        }
    }

    // MARK: - cleanUp

    func test_cleanUp_callIsNil() async throws {
        subject.call = .dummy()

        subject.cleanUp()

        XCTAssertNil(subject.call)
    }

    // MARK: - changeAudioState

    func test_changeAudioState_callSettingsUpdatedOnWebRTCCoordinatorAsExpected() async throws {
        try await assertWebRTCCoordinatorSettingsUpdated(
            expected: .init(audioOn: true)
        ) { try await subject.changeAudioState(isEnabled: true) }
    }

    // MARK: - changeSoundState

    func test_changeSoundState_callSettingsUpdatedOnWebRTCCoordinatorAsExpected() async throws {
        try await assertWebRTCCoordinatorSettingsUpdated(
            expected: .init(audioOutputOn: true)
        ) { try await subject.changeSoundState(isEnabled: true) }
    }

    // MARK: - changeCameraMode

    func test_changeCameraMode_callSettingsUpdatedOnWebRTCCoordinatorAsExpected() async throws {
        try await assertWebRTCCoordinatorSettingsUpdated(
            expected: .init(cameraPosition: .back)
        ) { try await subject.changeCameraMode(position: .back) }
    }

    // MARK: - changeSpeakerState

    func test_changeSpeakerState_callSettingsUpdatedOnWebRTCCoordinatorAsExpected() async throws {
        try await assertWebRTCCoordinatorSettingsUpdated(
            expected: .init(speakerOn: true)
        ) { try await subject.changeSpeakerState(isEnabled: true) }
    }

    // MARK: - changeTrackVisibility

    func test_changeTrackVisibility_shouldUpdateParticipantTrackVisibility() async throws {
        try await prepareAsConnected()

        await subject.changeTrackVisibility(
            for: .dummy(id: user.id),
            isVisible: true
        )

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .participants[self.user.id]?
                .showTrack == true
        }
    }

    // MARK: - updateTrackSize

    func test_updateTrackSize_shouldUpdateParticipantTrackSize() async throws {
        try await prepareAsConnected()

        await subject.updateTrackSize(
            .init(width: 100, height: 200),
            for: .dummy(id: user.id)
        )

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .participants[self.user.id]?
                .trackSize == .init(width: 100, height: 200)
        }
    }

    // MARK: - setVideoFilter

    func test_setVideoFilter_shouldSetVideoFilter() async throws {
        let expected = VideoFilter(id: .unique, name: .unique, filter: { _ in fatalError() })
        try await prepareAsConnected(videoFilter: nil)
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        subject.setVideoFilter(expected)
        await fulfillment { mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.last?.id == expected.id }

        let actual = try XCTUnwrap(mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.last)
        XCTAssertEqual(actual.id, expected.id)
        XCTAssertEqual(actual.name, expected.name)
    }

    // MARK: - startScreensharing

    func test_startScreensharing_typeIsInApp_includeAudioTrue_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .inApp, includeAudio: true)

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .inApp)
        XCTAssertEqual(actual.1, ownCapabilities)
        XCTAssertTrue(actual.2)
    }

    func test_startScreensharing_typeIsInApp_includeAudioFalse_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .inApp, includeAudio: false)

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .inApp)
        XCTAssertEqual(actual.1, ownCapabilities)
        XCTAssertFalse(actual.2)
    }

    func test_startScreensharing_typeIsBroadcast_includeAudioTrue_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .broadcast, includeAudio: true)

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .broadcast)
        XCTAssertEqual(actual.1, ownCapabilities)
        XCTAssertTrue(actual.2)
    }

    func test_startScreensharing_typeIsBroadcast_includeAudioFalse_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .broadcast, includeAudio: false)

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .broadcast)
        XCTAssertEqual(actual.1, ownCapabilities)
        XCTAssertFalse(actual.2)
    }

    // MARK: - stopScreensharing

    func test_stopScreensharing_shouldStopScreenSharing() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.stopScreensharing()

        XCTAssertEqual(mockPublisher.timesCalled(.stopScreenSharing), 1)
    }

    // MARK: - changePinState

    func test_changePinState_isEnabledTrue_shouldUpdateParticipantPin() async throws {
        try await prepareAsConnected()

        try await subject.changePinState(isEnabled: true, sessionId: user.id)

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .participants[self.user.id]?.pin?.isLocal == true
        }
    }

    func test_changePinState_isEnabledFalse_shouldUpdateParticipantPin() async throws {
        try await prepareAsConnected()
        try await mockWebRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .changePinState(isEnabled: true, sessionId: user.id)

        try await mockWebRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .changePinState(isEnabled: false, sessionId: user.id)

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter.participants[self.user.id]?.pin == nil
        }
    }

    // MARK: - startNoiseCancellation

    func test_startNoiseCancellation_shouldEnableNoiseCancellationForSession() async throws {
        try await prepareAsConnected()

        try await subject.startNoiseCancellation(user.id)

        XCTAssertEqual(
            mockWebRTCCoordinatorFactory.mockCoordinatorStack.sfuStack.service.startNoiseCancellationWasCalledWithRequest?
                .sessionID,
            user.id
        )
    }

    // MARK: - stopNoiseCancellation

    func test_stopNoiseCancellation_shouldDisableNoiseCancellationForSession() async throws {
        try await prepareAsConnected()

        try await subject.stopNoiseCancellation(user.id)

        XCTAssertEqual(
            mockWebRTCCoordinatorFactory.mockCoordinatorStack.sfuStack.service.stopNoiseCancellationWasCalledWithRequest?.sessionID,
            user.id
        )
    }

    // MARK: - focus

    func test_focus_shouldFocusOnSpecifiedPoint() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.focus(at: .init(x: 10, y: 20))

        await fulfillment {
            mockPublisher.recordedInputPayload(CGPoint.self, for: .focus)?.first == .init(x: 10, y: 20)
        }
        XCTAssertEqual(
            mockPublisher.recordedInputPayload(CGPoint.self, for: .focus)?.first,
            .init(x: 10, y: 20)
        )
    }

    // MARK: - addCapturePhotoOutput

    func test_addCapturePhotoOutput_shouldAddPhotoOutputToCaptureSession() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )
        let expected = AVCapturePhotoOutput()

        try await subject.addCapturePhotoOutput(expected)

        XCTAssertTrue(
            mockPublisher.recordedInputPayload(AVCapturePhotoOutput.self, for: .addCapturePhotoOutput)?.first === expected
        )
    }

    // MARK: - removeCapturePhotoOutput

    func test_removeCapturePhotoOutput_shouldRemovePhotoOutputFromCaptureSession() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )
        let expected = AVCapturePhotoOutput()

        try await subject.removeCapturePhotoOutput(expected)

        XCTAssertTrue(
            mockPublisher.recordedInputPayload(AVCapturePhotoOutput.self, for: .removeCapturePhotoOutput)?.first === expected
        )
    }

    // MARK: - addVideoOutput

    func test_addVideoOutput_shouldAddVideoOutputToCaptureSession() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )
        let expected = AVCaptureVideoDataOutput()

        try await subject.addVideoOutput(expected)

        XCTAssertTrue(
            mockPublisher.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .addVideoOutput)?.first === expected
        )
    }

    // MARK: - removeVideoOutput

    func test_removeVideoOutput_shouldRemoveVideoOutputFromCaptureSession() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )
        let expected = AVCaptureVideoDataOutput()

        try await subject.removeVideoOutput(expected)

        XCTAssertTrue(
            mockPublisher.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .removeVideoOutput)?.first === expected
        )
    }

    // MARK: - zoom

    func test_zoom_shouldZoomCameraBySpecifiedFactor() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.zoom(by: 32)

        XCTAssertEqual(
            mockPublisher.recordedInputPayload(CGFloat.self, for: .zoom)?.first,
            32
        )
    }

    // MARK: - setIncomingVideoQualitySettings

    func test_setIncomingVideoQualitySettings_shouldCallSetIncomingVideoQualitySettingsOnCoordinator() async throws {
        try await prepareAsConnected()
        let incomingVideoQualitySettings = IncomingVideoQualitySettings.manual(
            group: .custom(sessionIds: [.unique, .unique]),
            targetSize: .init(
                width: 11,
                height: 10
            )
        )

        await subject.setIncomingVideoQualitySettings(incomingVideoQualitySettings)

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .incomingVideoQualitySettings == incomingVideoQualitySettings
        }
    }

    // MARK: - setDisconnectionTimeout

    func test_setDisconnectionTimeout_shouldCallSetDisconnectionTimeoutOnCoordinator() async throws {
        try await prepareAsConnected()

        subject.setDisconnectionTimeout(11)

        XCTAssertEqual(
            mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateMachine
                .currentStage
                .context
                .disconnectionTimeout,
            11
        )
    }

    // MARK: - updatePublishOptions

    func test_updatePublishOptions_shouldCallUpdatePublishOptionsCoordinator() async throws {
        try await prepareAsConnected()

        await subject.updatePublishOptions(
            preferredVideoCodec: .vp9,
            maxBitrate: 1000
        )

        let publishOptions = await mockWebRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .stateAdapter
            .publishOptions
        XCTAssertEqual(publishOptions.video.count, 1)
        XCTAssertEqual(publishOptions.video.first?.codec, .vp9)
        XCTAssertEqual(publishOptions.video.first?.bitrate, 1000)
    }

    // MARK: - blockedEventReceived

    func test_blockedEventReceived_forCurrentUserInTheCurrentCall_transitionsToBlocked() async throws {
        let call = streamVideo.call(callType: .default, callId: .unique)
        subject.call = call
        await wait(for: 1)
        mockWebRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .stateMachine
            .transition(MockTestOnlyStage())

        await assertTransitionToStage(.blocked) {
            await call.onEvent(
                .coordinatorEvent(
                    .typeBlockedUserEvent(
                        .init(
                            callCid: call.cId,
                            createdAt: .distantPast,
                            user: .dummy(
                                id: self.user.id
                            )
                        )
                    )
                )
            )
        } handler: { _ in }
    }

    // MARK: - subscribeToParticipantsCountUpdatesEvent

    @MainActor
    func test_subscribeToParticipantsCountUpdatesEvent_whenCallIsNil_shouldNotSubscribe() async throws {
        let call = Call.dummy(callController: subject)
        subject.call = nil
        await wait(for: 0.5)

        await call.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantCountsUpdatedEvent(
                    .init(
                        anonymousParticipantCount: 10,
                        callCid: call.cId,
                        createdAt: .init(),
                        participantsCountByRole: [:],
                        sessionId: call.state.sessionId
                    )
                )
            )
        )

        await wait(for: 0.5)
        XCTAssertEqual(call.state.participantCount, 0)
        XCTAssertEqual(call.state.anonymousParticipantCount, 0)
    }

    @MainActor
    func test_subscribeToParticipantsCountUpdatesEvent_whenCallIsNotNil_shouldSubscribeAndUpdateParticipantCounts() async throws {
        let call = Call.dummy(callController: subject)
        await wait(for: 0.5)

        await call.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantCountsUpdatedEvent(
                    .init(
                        anonymousParticipantCount: 5,
                        callCid: call.cId,
                        createdAt: .init(),
                        participantsCountByRole: [
                            "anonymous": 6,
                            "user": 5
                        ],
                        sessionId: call.state.sessionId
                    )
                )
            )
        )

        await wait(for: 0.5)
        XCTAssertEqual(call.state.participantCount, 5)
        XCTAssertEqual(call.state.anonymousParticipantCount, 5)
    }

    @MainActor
    func test_subscribeToParticipantsCountUpdatesEvent_whenAnonymousCountIsZero_shouldUseRoleBasedCount() async throws {
        let call = Call.dummy(callController: subject)
        await wait(for: 0.5)

        await call.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantCountsUpdatedEvent(
                    .init(
                        anonymousParticipantCount: 0,
                        callCid: call.cId,
                        createdAt: .init(),
                        participantsCountByRole: [
                            "anonymous": 6,
                            "user": 5
                        ],
                        sessionId: call.state.sessionId
                    )
                )
            )
        )

        await wait(for: 0.5)
        XCTAssertEqual(call.state.participantCount, 5)
        XCTAssertEqual(call.state.anonymousParticipantCount, 6)
    }

    @MainActor
    func test_subscribeToParticipantsCountUpdatesEvent_whenNoAnonymousParticipants_shouldSetZeroAnonymousCount() async throws {
        let call = Call.dummy(callController: subject)
        await wait(for: 0.5)

        await call.onEvent(
            .coordinatorEvent(
                .typeCallSessionParticipantCountsUpdatedEvent(
                    .init(
                        anonymousParticipantCount: 0,
                        callCid: call.cId,
                        createdAt: .init(),
                        participantsCountByRole: [
                            "user": 5
                        ],
                        sessionId: call.state.sessionId
                    )
                )
            )
        )

        await wait(for: 0.5)
        XCTAssertEqual(call.state.participantCount, 5)
        XCTAssertEqual(call.state.anonymousParticipantCount, 0)
    }

    // MARK: - enableClientCapabilities

    func test_enableClientCapabilities_correctlyUpdatesStateAdapter() async throws {
        await subject.enableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(
            await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.clientCapabilities,
            [.subscriberVideoPause]
        )
    }

    // MARK: - disableClientCapabilities

    func test_disableClientCapabilities_correctlyUpdatesStateAdapter() async throws {
        await subject.disableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(
            await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.clientCapabilities,
            []
        )
    }

    // MARK: - Private helpers

    private func assertTransitionToStage(
        _ id: WebRTCCoordinator.StateMachine.Stage.ID,
        operation: @escaping @Sendable () async throws -> Void,
        handler: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let transitionExpectation = expectation(description: "WebRTCCoordinator is expected to transition to stage id:\(id).")

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let target = try await self
                    .mockWebRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .coordinator
                    .stateMachine
                    .publisher
                    .filter { $0.id == id }
                    .nextValue(timeout: defaultTimeout)

                await self.assertNoThrowAsync(
                    try await handler(target),
                    file: file,
                    line: line
                )
                transitionExpectation.fulfill()
            }
            group.addTask {
                await self.wait(for: 0.1)
                try await operation()
            }
            group.addTask {
                await self.fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
            }

            try await group.waitForAll()
        }
    }

    private func assertNoThrowAsync(
        _ expression: @autoclosure () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await expression()
        } catch {
            let thrower = { throw error }
            XCTAssertNoThrow(try thrower(), file: file, line: line)
        }
    }

    private func assertEqualAsync<T: Equatable>(
        _ expression: @autoclosure () async throws -> T,
        _ expected: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        let expectedValue = try await expected()
        XCTAssertEqual(value, expectedValue, file: file, line: line)
    }

    private func assertWebRTCCoordinatorSettingsUpdated(
        expected: @Sendable @escaping @autoclosure () -> CallSettings,
        _ operation: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        try await operation()
        await fulfillment(file: file, line: line) {
            let callSettings = await self.mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.callSettings
            return callSettings == expected()
        }
    }

    private func assertNilAsync<T>(
        _ expression: @autoclosure () async throws -> T?,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertNil(value, file: file, line: line)
    }

    private func prepareAsConnected(
        videoFilter: VideoFilter? = VideoFilter(
            id: .unique,
            name: .unique,
            filter: { _ in fatalError() }
        )
    ) async throws {
        mockWebRTCCoordinatorFactory.mockCoordinatorStack.sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let ownCapabilities = Set([OwnCapability.blockUsers, .changeMaxDuration])
        let callSettings = CallSettings(cameraPosition: .back)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter
            .set(sfuAdapter: mockWebRTCCoordinatorFactory.mockCoordinatorStack.sfuStack.adapter)
        if let videoFilter {
            await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(videoFilter: videoFilter)
        }
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(ownCapabilities: ownCapabilities)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.enqueueCallSettings { _ in callSettings }
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(sessionID: .unique)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(token: .unique)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(participantsCount: 12)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.set(anonymousCount: 22)
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter
            .set(participantPins: [PinInfo(isLocal: true, pinnedAt: .init())])
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter
            .enqueue { _ in [self.user.id: CallParticipant.dummy(id: self.user.id)] }
        try await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()
        await mockWebRTCCoordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter
            .set(statsAdapter: MockWebRTCStatsAdapter())

        await fulfillment {
            await self
                .mockWebRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateAdapter
                .participants.count == 1
        }
    }
}

final class MockTestOnlyStage: WebRTCCoordinator.StateMachine.Stage, @unchecked Sendable {
    convenience init() {
        self.init(id: .joined, context: .init())
    }

    override func transition(
        from previousStage: WebRTCCoordinator.StateMachine.Stage
    ) -> Self? {
        self
    }
}
