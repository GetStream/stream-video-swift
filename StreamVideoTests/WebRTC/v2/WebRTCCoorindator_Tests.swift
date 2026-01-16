//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCCoordinator_Tests: XCTestCase, @unchecked Sendable {
    /// Class variable that will be used by all test cases in the file. This ensure that only one
    /// PeerConnectionFactory will be created during tests, ensuring that WebRTC deallocation will
    /// only happen once all tests cases in the file ran.
    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var user: User! = .dummy()
    private lazy var apiKey: String! = .unique
    private lazy var callCid: String! = .unique
    private lazy var callSettings: CallSettings! = .default
    private lazy var mockCallAuthenticator: MockCallAuthenticator! = .init()
    private lazy var mockWebRTCAuthenticator: MockWebRTCAuthenticator! = .init()
    private lazy var mockPeerConnectionFactory: PeerConnectionFactory! = .build(
        audioProcessingModule: Self.videoConfig.audioProcessingModule,
        audioDeviceModuleSource: MockRTCAudioDeviceModule()
    )
    private lazy var rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory! =
        .init(peerConnectionFactory: mockPeerConnectionFactory)
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var subject: WebRTCCoordinator! = .init(
        user: user,
        apiKey: apiKey,
        callCid: callCid,
        videoConfig: Self.videoConfig,
        callSettings: callSettings,
        rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory,
        webRTCAuthenticator: mockWebRTCAuthenticator,
        callAuthentication: mockCallAuthenticator.authenticate
    )

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() async throws {
        subject = nil
        mockSFUStack = nil
        rtcPeerConnectionCoordinatorFactory = nil
        mockCallAuthenticator = nil
        callSettings = nil
        callCid = nil
        apiKey = nil
        user = nil
        mockPeerConnectionFactory = nil
        try await super.tearDown()
    }

    // MARK: - init

    func test_init_propagatesCallSettingsToStateAdapter() async {
        let callSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            cameraPosition: .back
        )
        self.callSettings = callSettings

        _ = subject

        await assertEqualAsync(
            await subject.stateAdapter.callSettings,
            callSettings
        )
    }

    // MARK: - connect

    func test_connect_shouldSetInitialCallSettingsAndTransitionStateMachine() async throws {
        let expectedCallSettings = CallSettings(cameraPosition: .back)
        let expectedOptions = CreateCallOptions(
            memberIds: [.unique, .unique],
            members: [.init(userId: .unique)],
            custom: [.unique: .bool(true)],
            settings: CallSettingsRequest(audio: .init(defaultDevice: .earpiece)),
            startsAt: .init(timeIntervalSince1970: 100),
            team: .unique
        )

        try await assertTransitionToStage(
            .connecting,
            operation: {
                try await self
                    .subject
                    .connect(
                        callSettings: expectedCallSettings,
                        options: expectedOptions,
                        ring: true,
                        notify: true,
                        source: .callKit
                    )
            }
        ) { stage in
            let expectedStage = try XCTUnwrap(stage as? WebRTCCoordinator.StateMachine.Stage.ConnectingStage)
            XCTAssertEqual(expectedStage.options?.memberIds, expectedOptions.memberIds)
            XCTAssertEqual(expectedStage.options?.members, expectedOptions.members)
            XCTAssertEqual(expectedStage.options?.custom, expectedOptions.custom)
            XCTAssertEqual(expectedStage.options?.settings?.audio?.defaultDevice, .earpiece)
            XCTAssertEqual(expectedStage.options?.startsAt, expectedOptions.startsAt)
            XCTAssertEqual(expectedStage.options?.team, expectedOptions.team)
            XCTAssertTrue(expectedStage.ring)
            XCTAssertTrue(expectedStage.notify)
            XCTAssertEqual(expectedStage.context.joinSource, .callKit)
            await self.assertEqualAsync(
                await self.subject.stateAdapter.initialCallSettings,
                expectedCallSettings
            )
        }
    }

    // MARK: - cleanUp

    func test_cleanUp_shouldCallStateAdapterCleanUp() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )
        let mockSubscriber = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .subscriber as? MockRTCPeerConnectionCoordinator
        )

        await subject.cleanUp()
        await fulfillment { await self.subject.stateAdapter.participants == [:] }

        XCTAssertEqual(mockPublisher.timesCalled(.close), 1)
        XCTAssertEqual(mockSubscriber.timesCalled(.close), 1)
        XCTAssertEqual(mockSFUStack.webSocket.timesCalled(.disconnectAsync), 1)
        await assertNilAsync(await subject.stateAdapter.publisher)
        await assertNilAsync(await subject.stateAdapter.subscriber)
        await assertNilAsync(await subject.stateAdapter.statsAdapter)
        await assertNilAsync(await subject.stateAdapter.sfuAdapter)
        await assertEqualAsync(await subject.stateAdapter.token, "")
        await assertEqualAsync(await subject.stateAdapter.sessionID, "")
        await assertEqualAsync(await subject.stateAdapter.ownCapabilities, [])
        await assertEqualAsync(await subject.stateAdapter.participantsCount, 0)
        await assertEqualAsync(await subject.stateAdapter.anonymousCount, 0)
        await assertEqualAsync(await subject.stateAdapter.participantPins, [])
    }

    // MARK: - leave

    func test_leave_shouldTransitionStateMachineToLeaving() async throws {
        mockWebRTCAuthenticator
            .stub(
                for: .authenticate,
                with: Result<(SFUAdapter, JoinCallResponse), Error>
                    .success((mockSFUStack.adapter, JoinCallResponse.dummy()))
            )
        mockWebRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )

        try await assertTransitionToStage(
            .connected,
            operation: {
                try await self
                    .subject
                    .connect(
                        callSettings: nil,
                        options: nil,
                        ring: true,
                        notify: true,
                        source: .inApp
                    )
            }
        ) { _ in
            await self.assertTransitionToStage(.leaving) {
                self.subject.leave()
            } handler: { _ in }
        }
    }

    // MARK: - changeCameraMode

    func test_changeCameraMode_shouldUpdateCameraPosition() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        let expected = await subject.stateAdapter.callSettings.cameraPosition.next()
        try await subject.changeCameraMode(position: expected)

        await fulfillment {
            let cameraPosition = await self.subject.stateAdapter.callSettings.cameraPosition
            return cameraPosition == expected
        }

        XCTAssertEqual(
            mockPublisher.recordedInputPayload(
                AVCaptureDevice.Position.self,
                for: .didUpdateCameraPosition
            )?.last,
            (expected == .front) ? .front : .back
        )
    }

    // MARK: - changeAudioState

    func test_changeAudioState_shouldUpdateAudioState() async throws {
        await subject.changeAudioState(isEnabled: false)

        await fulfillment {
            let currentValue = await self.subject.stateAdapter.callSettings.audioOn
            return currentValue == false
        }
    }

    // MARK: - changeSoundState

    func test_changeSoundState_shouldUpdateAudioOutputState() async throws {
        await subject.changeSoundState(isEnabled: false)

        await fulfillment {
            let currentValue = await self.subject.stateAdapter.callSettings.audioOutputOn
            return currentValue == false
        }
    }

    // MARK: - changeSpeakerState

    func test_changeSpeakerState_shouldUpdateSpeakerState() async throws {
        await subject.changeSpeakerState(isEnabled: false)

        await fulfillment {
            let currentValue = await self.subject.stateAdapter.callSettings.speakerOn
            return currentValue == false
        }
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
                .subject
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
                .subject
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
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        await subject.setVideoFilter(expected)

        let actual = try XCTUnwrap(mockPublisher.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.last)
        XCTAssertEqual(actual.id, expected.id)
        XCTAssertEqual(actual.name, expected.name)
    }

    // MARK: - startScreensharing

    func test_startScreensharing_typeIsInApp_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await subject.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .inApp, includeAudio: true)
        await fulfillment { mockPublisher.timesCalled(.beginScreenSharing) == 1 }

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .inApp)
        XCTAssertEqual(actual.1, ownCapabilities)
    }

    func test_startScreensharing_typeIsBroadcast_shouldBeginScreenSharing() async throws {
        try await prepareAsConnected()
        let ownCapabilities = [OwnCapability.createReaction]
        await subject.stateAdapter.set(ownCapabilities: Set(ownCapabilities))
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.startScreensharing(type: .broadcast, includeAudio: true)
        await fulfillment { mockPublisher.timesCalled(.beginScreenSharing) == 1 }

        let actual = try XCTUnwrap(
            mockPublisher.recordedInputPayload(
                (ScreensharingType, [OwnCapability], Bool).self,
                for: .beginScreenSharing
            )?.first
        )
        XCTAssertEqual(actual.0, .broadcast)
        XCTAssertEqual(actual.1, ownCapabilities)
    }

    // MARK: - stopScreensharing

    func test_stopScreensharing_shouldStopScreenSharing() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
                .stateAdapter
                .publisher as? MockRTCPeerConnectionCoordinator
        )

        try await subject.stopScreensharing()

        await fulfillment {
            mockPublisher.timesCalled(.stopScreenSharing) == 1
        }
    }

    // MARK: - changePinState

    func test_changePinState_isEnabledTrue_shouldUpdateParticipantPin() async throws {
        try await prepareAsConnected()

        try await subject.changePinState(isEnabled: true, sessionId: user.id)

        await fulfillment {
            await self
                .subject
                .stateAdapter
                .participants[self.user.id]?
                .pin?.isLocal == true
        }
    }

    func test_changePinState_isEnabledFalse_shouldUpdateParticipantPin() async throws {
        try await prepareAsConnected()
        try await subject.changePinState(isEnabled: true, sessionId: user.id)

        try await subject.changePinState(isEnabled: false, sessionId: user.id)

        await fulfillment {
            await self
                .subject
                .stateAdapter
                .participants[self.user.id]?
                .pin == nil
        }
    }

    // MARK: - startNoiseCancellation

    func test_startNoiseCancellation_shouldEnableNoiseCancellationForSession() async throws {
        try await prepareAsConnected()

        try await subject.startNoiseCancellation(user.id)

        XCTAssertEqual(
            mockSFUStack.service.startNoiseCancellationWasCalledWithRequest?.sessionID,
            user.id
        )
    }

    // MARK: - stopNoiseCancellation

    func test_stopNoiseCancellation_shouldDisableNoiseCancellationForSession() async throws {
        try await prepareAsConnected()

        try await subject.stopNoiseCancellation(user.id)

        XCTAssertEqual(
            mockSFUStack.service.stopNoiseCancellationWasCalledWithRequest?.sessionID,
            user.id
        )
    }

    // MARK: - focus

    func test_focus_shouldFocusOnSpecifiedPoint() async throws {
        try await prepareAsConnected()
        let mockPublisher = try await XCTAsyncUnwrap(
            await subject
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
            await subject
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
            await subject
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
            await subject
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
            await subject
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
            await subject
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

    func test_setIncomingVideoQualitySettings_correctlyUpdatesStateAdapter() async throws {
        try await prepareAsConnected()
        let incomingVideoQualitySettings = IncomingVideoQualitySettings.manual(
            group: .custom(sessionIds: [.unique, .unique]),
            targetSize: .init(
                width: 11,
                height: 10
            )
        )

        await subject.setIncomingVideoQualitySettings(incomingVideoQualitySettings)

        await assertEqualAsync(
            await subject.stateAdapter.incomingVideoQualitySettings,
            incomingVideoQualitySettings
        )
    }

    // MARK: - setDisconnectionTimeout

    func test_setDisconnectionTimeout_correctlyUpdatesStageContext() async throws {
        try await prepareAsConnected()

        subject.setDisconnectionTimeout(11)

        XCTAssertEqual(
            subject.stateMachine.currentStage.context.disconnectionTimeout,
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

        let publishOptions = await subject
            .stateAdapter
            .publishOptions
        XCTAssertEqual(publishOptions.video.count, 1)
        let videoPublishOptions = try XCTUnwrap(publishOptions.video.first)
        XCTAssertEqual(videoPublishOptions.codec, .vp9)
        XCTAssertEqual(videoPublishOptions.bitrate, 1000)
    }

    // MARK: - enableClientCapabilities

    func test_enableClientCapabilities_correctlyUpdatesStateAdapter() async throws {
        await subject.enableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(
            await subject.stateAdapter.clientCapabilities,
            [.subscriberVideoPause]
        )
    }

    // MARK: - disableClientCapabilities

    func test_disableClientCapabilities_correctlyUpdatesStateAdapter() async throws {
        await subject.disableClientCapabilities([.subscriberVideoPause])

        await assertEqualAsync(
            await subject.stateAdapter.clientCapabilities,
            []
        )
    }

    // MARK: - Private helpers

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
                    .subject
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
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let ownCapabilities = Set([OwnCapability.blockUsers, .changeMaxDuration])
        let callSettings = CallSettings(cameraPosition: .back)
        await subject.stateAdapter.set(sfuAdapter: mockSFUStack.adapter)
        if let videoFilter {
            await subject.stateAdapter.set(videoFilter: videoFilter)
        }
        await subject.stateAdapter.set(ownCapabilities: ownCapabilities)
        await subject.stateAdapter.enqueueCallSettings { _ in callSettings }
        await subject.stateAdapter.set(sessionID: .unique)
        await subject.stateAdapter.set(token: .unique)
        await subject.stateAdapter.set(participantsCount: 12)
        await subject.stateAdapter.set(anonymousCount: 22)
        await subject.stateAdapter.set(participantPins: [PinInfo(isLocal: true, pinnedAt: .init())])
        await subject.stateAdapter.enqueue { _ in [self.user.id: CallParticipant.dummy(id: self.user.id)] }
        try await subject.stateAdapter.configurePeerConnections()
        let statsAdapter = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: .unique,
            isTracingEnabled: true,
            trackStorage: await subject.stateAdapter.trackStorage
        )
        await subject.stateAdapter.set(statsAdapter: statsAdapter)
    }
}
