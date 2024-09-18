//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class CallController_Tests: XCTestCase, @unchecked Sendable {

    private static var videoConfig: VideoConfig! = .dummy()

    private lazy var httpClient: HTTPClient_Mock! = HTTPClient_Mock()
    private lazy var defaultAPI: DefaultAPI! = DefaultAPI(
            basePath: "example.com",
            transport: httpClient,
            middlewares: []
        )
    private lazy var user: User! = .dummy()
    private lazy var callId: String! = .unique
    private lazy var callType: String! = .default
    private lazy var apiKey: String! = .unique
    private lazy var cachedLocation: String? = .unique
    private lazy var mockWebRTCCoordinatorFactory: MockWebRTCCoordinatorFactory! = .init()
    private lazy var subject: CallController! = .init(
        defaultAPI: defaultAPI,
        user: user,
        callId: callId,
        callType: callType,
        apiKey: apiKey,
        videoConfig: Self.videoConfig,
        cachedLocation: cachedLocation,
        webRTCCoordinatorFactory: mockWebRTCCoordinatorFactory
    )

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        subject = nil
        mockWebRTCCoordinatorFactory = nil
        cachedLocation = nil
        apiKey = nil
        callType = nil
        callId = nil
        user = nil
        defaultAPI = nil
        httpClient = nil
        super.tearDown()
    }

    // MARK: - joinCall

    func test_joinCall_coordinatorTransitionsToConnecting() async throws {
        let callSettings = CallSettings(cameraPosition: .back)
        let options = CreateCallOptions(team: .unique)

        try await assertTransitionToStage(
            .connecting,
            operation: {
                try await self
                    .subject
                    .joinCall(
                        create: true,
                        callSettings: callSettings,
                        options: options,
                        ring: true,
                        notify: true
                    )
            }
        ) { stage in
            let expectedStage = try XCTUnwrap(stage as? WebRTCCoordinator.StateMachine.Stage.ConnectingStage)
            XCTAssertEqual(expectedStage.options?.team, options.team)
            XCTAssertTrue(expectedStage.ring)
            XCTAssertTrue(expectedStage.notify)
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

    // MARK: - Private helpers

    private func assertTransitionToStage(
        _ id: WebRTCCoordinator.StateMachine.Stage.ID,
        operation: @escaping () async throws -> Void,
        handler: @escaping (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
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

//    private var webRTCClient: WebRTCClient!
//
//    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
//
//    override public func setUp() {
//        super.setUp()
//        streamVideo = StreamVideo(
//            apiKey: apiKey,
//            user: user,
//            token: StreamVideo.mockToken,
//            videoConfig: videoConfig,
//            tokenProvider: { _ in }
//        )
//    }
//
//    func test_callController_joinCall_webRTCClientSignalChannelUsesTheExpectedConnectURL() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController()
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//
//        // Then
//        XCTAssertEqual(webRTCClient.sfuAdapter?.connectURL.absoluteString, "wss://test.com/ws")
//    }
//
//    func test_callController_reconnectionSuccess() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController(shouldReconnect: true)
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        webRTCClient.sfuAdapter?.connect()
//        try await waitForCallEvent()
//        let signalChannel = webRTCClient.signalChannel!
//        let engine = signalChannel.engine as! WebSocketEngine_Mock
//        engine.simulateConnectionSuccess()
//        try await waitForCallEvent()
//        engine.simulateDisconnect()
//        try await waitForCallEvent(nanoseconds: 5_000_000_000)
//        webRTCClient?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
//        try await waitForCallEvent()
//
//        // Then
//        XCTAssert(callController.call?.state.reconnectionStatus == .reconnecting)
//
//        // When
//        try await waitForCallEvent()
//        engine.simulateConnectionSuccess()
//        try await waitForCallEvent()
//        webRTCClient?.webSocketClient(
//            didUpdateConnectionState: .connected(
//                healthCheckInfo: HealthCheckInfo(
//                    sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse()
//                )
//            )
//        )
//        try await waitForCallEvent()
//
//        // Then
//        XCTAssert(callController.call?.state.reconnectionStatus == .connected)
//    }
//
//    func test_callController_migrationSuccess() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController(shouldReconnect: true)
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        webRTCClient.sfuAdapter?.connect()
//        try await waitForCallEvent()
//        let signalChannel = webRTCClient.signalChannel!
//        let engine = signalChannel.engine as! WebSocketEngine_Mock
//        engine.simulateConnectionSuccess()
//        try await waitForCallEvent()
//        webRTCClient.eventNotificationCenter.process(.sfuEvent(.goAway(Stream_Video_Sfu_Event_GoAway())))
//        try await waitForCallEvent()
//
//        // Then
//        XCTAssert(callController.call?.state.reconnectionStatus == .migrating)
//
//        // When
//        try await waitForCallEvent()
//        engine.simulateConnectionSuccess()
//        try await waitForCallEvent()
//        webRTCClient?.webSocketClient(
//            didUpdateConnectionState: .connected(
//                healthCheckInfo: HealthCheckInfo(
//                    sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse()
//                )
//            )
//        )
//        webRTCClient?.onSessionMigrationCompleted?()
//        try await waitForCallEvent()
//
//        // Then
//        XCTAssert(callController.call?.state.reconnectionStatus == .connected)
//    }
//
//    func test_callController_reconnectionFailure() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        webRTCClient.sfuAdapter?.connect()
//        try await waitForCallEvent()
//        let signalChannel = webRTCClient.signalChannel!
//        let engine = signalChannel.engine as! WebSocketEngine_Mock
//        engine.simulateConnectionSuccess()
//        try await waitForCallEvent()
//        engine.simulateDisconnect()
//        try await waitForCallEvent(nanoseconds: 5_000_000_000)
//        webRTCClient?.onSignalConnectionStateChange?(.disconnected(source: .noPongReceived))
//        try await waitForCallEvent()
//
//        // Then
//        XCTAssert(callController.call?.state.reconnectionStatus == .reconnecting)
//
//        // When
//        try await waitForCallEvent(nanoseconds: 5_500_000_000)
//
//        // Then
//        XCTAssert(callController.call == nil)
//    }
//
//    func test_callController_updateCallInfo() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        var callResponse = MockResponseBuilder().makeCallResponse(cid: callCid)
//        callResponse.backstage = true
//        call?.state.update(from: callResponse)
//
//        // Then
//        XCTAssert(callController.call?.state.backstage == true)
//    }
//
//    @MainActor
//    func test_callController_updateRecordingState() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController(recording: true)
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        let event = CallRecordingStartedEvent(callCid: callCid, createdAt: Date())
//        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRecordingStartedEvent(event)))
//
//        // Then
//        try await XCTAssertWithDelay(callController.call?.state.recordingState == .recording)
//    }
//
//    @MainActor
//    func test_callController_updateRecordingStateDifferentCallCid() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        let event = CallRecordingStartedEvent(callCid: "test", createdAt: Date())
//        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRecordingStartedEvent(event)))
//
//        // Then
//        try await XCTAssertWithDelay(callController.call?.state.recordingState == .noRecording)
//    }
//
//    func test_callController_cleanup() async throws {
//        // Given
//        webRTCClient = makeWebRTCClient()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        callController.cleanUp()
//
//        // Then
//        XCTAssert(callController.call == nil)
//    }
//
//    func test_callController_changeAudioState() async throws {
//        // Given
//        webRTCClient = try makeWebRTCClientWithMuteStatesResponse()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        try await callController.changeAudioState(isEnabled: false)
//
//        // Then
//        XCTAssert(webRTCClient.callSettings.audioOn == false)
//    }
//
//    func test_callController_changeVideoState() async throws {
//        // Given
//        webRTCClient = try makeWebRTCClientWithMuteStatesResponse()
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        try await callController.changeVideoState(isEnabled: false)
//
//        // Then
//        XCTAssert(webRTCClient.callSettings.videoOn == false)
//    }
//
//    func test_callController_changeTrackVisibility() async throws {
//        // Given
//        let sessionId = "test"
//        webRTCClient = makeWebRTCClient()
//        let participant = CallParticipant.dummy(id: sessionId)
//        await webRTCClient.state.update(callParticipants: [sessionId: participant])
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        await callController.changeTrackVisibility(for: participant, isVisible: true)
//
//        // Then
//        let updated = await webRTCClient.state.callParticipants[sessionId]
//        XCTAssert(updated?.showTrack == true)
//    }
//
//    func test_callController_updateTrackSize() async throws {
//        // Given
//        let sessionId = "test"
//        let size = CGSize(width: 100, height: 100)
//        webRTCClient = makeWebRTCClient()
//        let participant = CallParticipant.dummy(id: sessionId)
//        await webRTCClient.state.update(callParticipants: [sessionId: participant])
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        await callController.updateTrackSize(size, for: participant)
//
//        // Then
//        let updated = await webRTCClient.state.callParticipants[sessionId]
//        XCTAssert(updated?.trackSize == size)
//    }
//
//    func test_callController_pinAndUnpin() async throws {
//        // Given
//        let sessionId = "test"
//        webRTCClient = makeWebRTCClient()
//        let participant = CallParticipant.dummy(id: sessionId)
//        await webRTCClient.state.update(callParticipants: [sessionId: participant])
//        let callController = makeCallController()
//        let call = streamVideo?.call(callType: callType, callId: callId)
//
//        // When
//        try await callController.joinCall(
//            callType: callType,
//            callId: callId,
//            callSettings: CallSettings(),
//            options: nil
//        )
//        callController.call = call
//        try await callController.changePinState(isEnabled: true, sessionId: sessionId)
//
//        // Then
//        var updated = await webRTCClient.state.callParticipants[sessionId]
//        XCTAssertNotNil(updated?.pin)
//        XCTAssertEqual(updated?.pin?.isLocal, true)
//
//        // When
//        try await callController.changePinState(isEnabled: false, sessionId: sessionId)
//
//        // Then
//        updated = await webRTCClient.state.callParticipants[sessionId]
//        XCTAssertNil(updated?.pin)
//    }
//
//    // MARK: - private
//
//    private func makeCallController(
//        shouldReconnect: Bool = false,
//        recording: Bool = false
//    ) -> CallController {
//        let httpClient = HTTPClient_Mock()
//        let joinCallResponse = MockResponseBuilder().makeJoinCallResponse(cid: callCid, recording: recording)
//        let data = try! JSONEncoder.default.encode(joinCallResponse)
//        var responses = [data]
//        if shouldReconnect {
//            responses.append(data)
//        }
//        httpClient.dataResponses = responses
//        let defaultAPI = DefaultAPI(
//            basePath: "example.com",
//            transport: httpClient,
//            middlewares: []
//        )
//        let callController = CallController(
//            defaultAPI: defaultAPI,
//            user: user,
//            callId: callId,
//            callType: callType,
//            apiKey: apiKey,
//            videoConfig: videoConfig,
//            cachedLocation: nil,
//            environment: .mock(with: webRTCClient)
//        )
//        return callController
//    }
//
//    private func makeWebRTCClientWithMuteStatesResponse() throws -> WebRTCClient {
//        let response = try Stream_Video_Sfu_Signal_UpdateMuteStatesResponse().serializedData()
//        let httpClient = HTTPClient_Mock()
//        httpClient.dataResponses = [response]
//        return makeWebRTCClient(httpClient: httpClient)
//    }
//
//    private func makeWebRTCClient(httpClient: HTTPClient_Mock? = nil) -> WebRTCClient {
//        let time = VirtualTime()
//        VirtualTimeTimer.time = time
//        var environment = WebSocketClient.Environment.mock
//        environment.timerType = VirtualTimeTimer.self
//        if let httpClient {
//            environment.httpClientBuilder = {
//                httpClient
//            }
//        }
//
//        let webRTCClient = WebRTCClient(
//            user: StreamVideo.mockUser,
//            apiKey: StreamVideo.apiKey,
//            hostname: "test.com",
//            webSocketURLString: "wss://test.com/ws",
//            token: StreamVideo.mockToken.rawValue,
//            callCid: callCid,
//            sessionID: nil,
//            ownCapabilities: [.sendAudio, .sendVideo],
//            videoConfig: .dummy(),
//            audioSettings: AudioSettings(
//                accessRequestEnabled: true,
//                defaultDevice: .speaker,
//                micDefaultOn: true,
//                opusDtxEnabled: true,
//                redundantCodingEnabled: true,
//                speakerDefaultOn: true
//            ),
//            environment: environment
//        )
//        return webRTCClient
//    }
    // }
//
    // extension CallController.Environment {
//
//    static func mock(with webRTCClient: WebRTCClient) -> Self {
//        .init(
//            webRTCBuilder: { _, _, _, _, _, _, _, _, _, _, _ in
//                webRTCClient
//            },
//            sfuReconnectionTime: 5
//        )
//    }
}
