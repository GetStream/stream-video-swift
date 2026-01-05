//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_JoiningStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.connected, .fastReconnected, .migrated]
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .joining(.init())

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
    }

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        allOtherStages = nil
        mockCoordinatorStack = nil
        validStages = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .joining)
    }

    // MARK: - transition

    func test_transition() {
        for nextStage in allOtherStages {
            if validStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage))
            }
        }
    }

    // MARK: - transition from connected with isRejoiningFromSessionID == nil

    func test_transition_fromConnectedWithoutCoordinator_updatesReconnectionStrategy() async throws {
        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .fast(disconnectedSince: .init(), deadline: 10)))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .rejoin) }

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .rejoin))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .rejoin) }

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .migrate))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .migrate) }

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .disconnected))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .disconnected) }

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .unknown))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .disconnected) }
    }

    func test_transition_fromConnectedWithoutSFUAdapter_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 10)
        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .rejoin) }
    }

    func test_transition_fromConnected_sendsExpectedJoinRequest() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11

        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let request = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_SfuRequest.self,
                    for: .sendMessage
                )?.first
            )
            let sessionID = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            let token = await mockCoordinatorStack?.coordinator.stateAdapter.token
            XCTAssertEqual(request.joinRequest.sessionID, sessionID)
            XCTAssertEqual(request.joinRequest.clientDetails, SystemEnvironment.clientDetails)
            XCTAssertFalse(request.joinRequest.subscriberSdp.isEmpty)
            XCTAssertFalse(request.joinRequest.fastReconnect)
            XCTAssertEqual(request.joinRequest.token, token)
            XCTAssertEqual(request.joinRequest.reconnectDetails.reconnectAttempt, 0)
            XCTAssertTrue(request.joinRequest.reconnectDetails.announcedTracks.isEmpty)
            XCTAssertTrue(request.joinRequest.reconnectDetails.subscriptions.isEmpty)
            XCTAssertEqual(request.joinRequest.reconnectDetails.strategy, .unspecified)
            XCTAssertTrue(request.joinRequest.reconnectDetails.previousSessionID.isEmpty)
            XCTAssertTrue(request.joinRequest.reconnectDetails.fromSfuID.isEmpty)
            XCTAssertEqual(request.joinRequest.capabilities, [.subscriberVideoPause])
        }
    }

    func test_transition_fromConnected_createsSFUEventObserver() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] target in
            XCTAssertTrue(
                target.context.sfuEventObserver?.sfuAdapter === mockCoordinatorStack?.sfuStack.adapter
            )
        }
    }

    func test_transition_fromConnected_updatesReconnectAttemptsOnStatsAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        let statsAdapter = MockWebRTCStatsAdapter()
        await subject
            .context
            .coordinator?
            .stateAdapter
            .set(statsAdapter: statsAdapter)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                statsAdapter.reconnectAttempts,
                target.context.reconnectAttempts
            )
        }
    }

    func test_transition_fromConnected_joinResponseReceiveTimeouts() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                (target.context.flowError as? ClientError)?.localizedDescription,
                "Operation timed out"
            )
        }
    }

    func test_transition_fromConnectedReceivesJoinResponse_updatesCallSettingsOnStateAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            let publisher = await target.context.coordinator?.stateAdapter.publisher
            let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
            XCTAssertEqual(mockPublisher.timesCalled(.didUpdateCallSettings), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedReceivesJoinResponse_sendsHealthCheck() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let requests = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_HealthCheckRequest.self,
                    for: .sendMessage
                )
            )
            XCTAssertEqual(requests.count, 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedSFUNotConnected_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in XCTAssertTrue(target.context.flowError is ClientError) }
        cancellable.cancel()
    }

    func test_transition_fromConnected_configuresPeerConnections() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) {
            let publisher = await $0.context.coordinator?.stateAdapter.publisher
            let subscriber = await $0.context.coordinator?.stateAdapter.subscriber
            XCTAssertNotNil(publisher)
            XCTAssertNotNil(subscriber)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnected_configuresAudioSession() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) {
            let audioSession = await $0.context.coordinator?.stateAdapter.audioSession
            XCTAssertNotNil(audioSession?.delegate)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedSFUConnected_updatesParticipants() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())

        var response = Stream_Video_Sfu_Event_JoinResponse()
        let participantBuilder: () -> Stream_Video_Sfu_Models_Participant = {
            var result = Stream_Video_Sfu_Models_Participant()
            result.sessionID = .unique
            result.userID = .unique
            result.name = .unique
            result.publishedTracks = [.video]
            result.isSpeaking = false
            result.isDominantSpeaker = false
            result.connectionQuality = .good
            result.joinedAt = .init(timeIntervalSince1970: 1)
            result.audioLevel = 10
            return result
        }
        response.callState.participants = [
            participantBuilder(),
            participantBuilder(),
            participantBuilder()
        ]
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { [mockCoordinatorStack] target in
            let participants = await target.context.coordinator?.stateAdapter.participants
            XCTAssertEqual(participants?.count, 3)
            XCTAssertEqual(mockCoordinatorStack?.webRTCAuthenticator.timesCalled(.waitForConnect), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedReceivesJoinResponse_updateFastReconnectDeadlineSeconds() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { target in
            XCTAssertEqual(target.context.fastReconnectDeadlineSeconds, 22)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedSFUConnected_reportsTelemetry() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { _ in }

        cancellable.cancel()

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID, unifiedSessionId)

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTAssertTrue(true)
        case .reconnection:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    // MARK: - transition from connected with isRejoiningFromSessionID != nil

    func test_transition_fromConnectedWithRejoinWithoutCoordinator_transitionsToDisconnected() async throws {
        /// Only the ``.rejoin`` strategy is valid during the rejoin flow.
        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .rejoin, isRejoiningFromSessionID: .unique))
        ) { _ in }
    }

    func test_transition_fromConnectedWithRejoinWithoutSFUAdapter_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: .joining(.init(
                coordinator: mockCoordinatorStack.coordinator,
                reconnectionStrategy: .rejoin,
                isRejoiningFromSessionID: .unique
            ))
        ) { _ in }
    }

    func test_transition_fromConnectedWithRejoin_sendsExpectedJoinRequest() async throws {
        throw XCTSkip("To be fixed")
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let previousSessionId = String.unique
        subject.context.isRejoiningFromSessionID = previousSessionId
        subject.context.reconnectAttempts = 11
        let mockRTCCoordinator = try MockRTCPeerConnectionCoordinator(
            sessionId: "stub-session-id",
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockRTCCoordinator?.stub(for: .mid, with: "test-mid")
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()
        mockTrack.isEnabled = true
        mockRTCCoordinator?.stub(for: .localTrack, with: mockTrack)
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = mockRTCCoordinator
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = mockRTCCoordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter.enqueue { _ in
                [
                    "0": .dummy(id: "0", hasVideo: true, hasAudio: false, isScreenSharing: false),
                    "1": .dummy(id: "1", hasVideo: false, hasAudio: true, isScreenSharing: false),
                    "2": .dummy(id: "2", hasVideo: false, hasAudio: false, isScreenSharing: true)
                ]
            }

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let request = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_SfuRequest.self,
                    for: .sendMessage
                )?.first
            )
            let sessionID = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            let token = await mockCoordinatorStack?.coordinator.stateAdapter.token
            let sortedSubscriptions = request.joinRequest.reconnectDetails.subscriptions.sorted { $0.userID < $1.userID }
            XCTAssertEqual(request.joinRequest.sessionID, sessionID)
            XCTAssertEqual(request.joinRequest.clientDetails, SystemEnvironment.clientDetails)
            XCTAssertFalse(request.joinRequest.subscriberSdp.isEmpty)
            XCTAssertFalse(request.joinRequest.fastReconnect)
            XCTAssertEqual(request.joinRequest.token, token)
            XCTAssertEqual(request.joinRequest.reconnectDetails.reconnectAttempt, 11)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].trackType, .audio)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[0].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].trackType, .video)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[1].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].trackType, .screenShare)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[2].muted)
            XCTAssertEqual(sortedSubscriptions[0].userID, "0")
            XCTAssertEqual(sortedSubscriptions[0].sessionID, "0")
            XCTAssertEqual(sortedSubscriptions[0].trackType, .video)
            XCTAssertEqual(sortedSubscriptions[1].userID, "1")
            XCTAssertEqual(sortedSubscriptions[1].sessionID, "1")
            XCTAssertEqual(sortedSubscriptions[1].trackType, .audio)
            XCTAssertEqual(sortedSubscriptions[2].userID, "2")
            XCTAssertEqual(sortedSubscriptions[2].sessionID, "2")
            XCTAssertEqual(sortedSubscriptions[2].trackType, .screenShare)
            XCTAssertEqual(request.joinRequest.reconnectDetails.strategy, .rejoin)
            XCTAssertEqual(request.joinRequest.reconnectDetails.previousSessionID, previousSessionId)
            XCTAssertTrue(request.joinRequest.reconnectDetails.fromSfuID.isEmpty)
        }
    }

    func test_transition_fromConnectedWithRejoin_increasesReconnectAttempts() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { XCTAssertEqual($0.context.reconnectAttempts, 12) }
    }

    func test_transition_fromConnectedWithRejoin_doesNotCreateSFUEventObserver() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        let sfuEventAdapter = SFUEventAdapter(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        subject.context.sfuEventObserver = sfuEventAdapter

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] target in
            XCTAssertTrue(
                target.context.sfuEventObserver === sfuEventAdapter
            )
            XCTAssertTrue(
                target.context.sfuEventObserver?.sfuAdapter === mockCoordinatorStack?.sfuStack.adapter
            )
        }
    }

    func test_transition_fromConnectedWithRejoin_updatesReconnectAttemptsOnStatsAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        subject.context.sfuEventObserver = SFUEventAdapter(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        let statsAdapter = MockWebRTCStatsAdapter()
        await subject
            .context
            .coordinator?
            .stateAdapter
            .set(statsAdapter: statsAdapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                statsAdapter.reconnectAttempts,
                target.context.reconnectAttempts
            )
        }
    }

    func test_transition_fromConnectedWithRejoin_joinResponseReceiveTimeouts() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                (target.context.flowError as? ClientError)?.localizedDescription,
                "Operation timed out"
            )
        }
    }

    func test_transition_fromConnectedWithRejoinReceivesJoinResponse_updatesCallSettingsOnStateAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            let publisher = await target.context.coordinator?.stateAdapter.publisher
            let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
            XCTAssertEqual(mockPublisher.timesCalled(.didUpdateCallSettings), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoinReceivesJoinResponse_sendsHealthCheck() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let requests = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_HealthCheckRequest.self,
                    for: .sendMessage
                )
            )
            XCTAssertEqual(requests.count, 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoinSFUNotConnected_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in XCTAssertTrue(target.context.flowError is ClientError) }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoin_configuresPeerConnections() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) {
            let publisher = await $0.context.coordinator?.stateAdapter.publisher
            let subscriber = await $0.context.coordinator?.stateAdapter.subscriber
            XCTAssertNotNil(publisher)
            XCTAssertNotNil(subscriber)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoin_configuresAudioSession() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) {
            let audioSession = await $0.context.coordinator?.stateAdapter.audioSession
            XCTAssertNotNil(audioSession?.delegate)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoinSFUConnected_updatesParticipantsAndFiltersOutUserWithPreviousSessionId(
    ) async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())

        var response = Stream_Video_Sfu_Event_JoinResponse()
        let participantBuilder: (String?) -> Stream_Video_Sfu_Models_Participant = { sessionId in
            var result = Stream_Video_Sfu_Models_Participant()
            result.sessionID = sessionId ?? .unique
            result.userID = .unique
            result.name = .unique
            result.publishedTracks = [.video]
            result.isSpeaking = false
            result.isDominantSpeaker = false
            result.connectionQuality = .good
            result.joinedAt = .init(timeIntervalSince1970: 1)
            result.audioLevel = 10
            return result
        }
        response.callState.participants = [
            participantBuilder(nil),
            participantBuilder(nil),
            participantBuilder(nil),
            participantBuilder(subject.context.isRejoiningFromSessionID)
        ]
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { [mockCoordinatorStack] target in
            let participants = await target.context.coordinator?.stateAdapter.participants
            XCTAssertEqual(participants?.count, 3)
            XCTAssertEqual(mockCoordinatorStack?.webRTCAuthenticator.timesCalled(.waitForConnect), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoinReceivesJoinResponse_updateFastReconnectDeadlineSeconds() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { target in
            XCTAssertEqual(target.context.fastReconnectDeadlineSeconds, 22)
        }
        cancellable.cancel()
    }

    func test_transition_fromConnectedWithRejoinSFUConnected_reportsTelemetry() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.isRejoiningFromSessionID = .unique
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .connected,
            expectedTarget: .joined,
            subject: subject
        ) { _ in }

        cancellable.cancel()

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID, unifiedSessionId)

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTFail()
        case let .reconnection(reconnection):
            XCTAssertEqual(reconnection.strategy, .rejoin)
        case .none:
            XCTFail()
        }
    }

    // MARK: - transition from fastReconnected

    func test_transition_fromFastReconnected_doeNotConfigurePeerConnections() async throws {
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .fastReconnected,
            expectedTarget: .disconnected,
            subject: .joining(.init(
                coordinator: mockCoordinatorStack.coordinator,
                reconnectionStrategy: .fast(disconnectedSince: .init(), deadline: 10)
            ))
        ) {
            let publisher = await $0.context.coordinator?.stateAdapter.publisher
            let subscriber = await $0.context.coordinator?.stateAdapter.subscriber
            XCTAssertNil(publisher)
            XCTAssertNil(subscriber)
        }
    }

    func test_transition_fromFastReconnected_sendsExpectedJoinRequest() async throws {
        throw XCTSkip("To be fixed")
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        let mockRTCCoordinator = try MockRTCPeerConnectionCoordinator(
            sessionId: "stub-session-id",
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockRTCCoordinator?.stub(for: .mid, with: "test-mid")
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()
        mockTrack.isEnabled = true
        mockRTCCoordinator?.stub(for: .localTrack, with: mockTrack)
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = mockRTCCoordinator
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = mockRTCCoordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter.enqueue { _ in
                [
                    "0": .dummy(id: "0", hasVideo: true, hasAudio: false, isScreenSharing: false),
                    "1": .dummy(id: "1", hasVideo: false, hasAudio: true, isScreenSharing: false),
                    "2": .dummy(id: "2", hasVideo: false, hasAudio: false, isScreenSharing: true)
                ]
            }
        /// We manually trigger the peerConnection configuration to allow us to test what will happen to
        /// the existing connections.
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()

        try await assertTransition(
            from: .fastReconnected,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let request = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_SfuRequest.self,
                    for: .sendMessage
                )?.first
            )
            let sessionID = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            let token = await mockCoordinatorStack?.coordinator.stateAdapter.token
            let sortedSubscriptions = request.joinRequest.reconnectDetails.subscriptions.sorted { $0.userID < $1.userID }
            XCTAssertEqual(request.joinRequest.sessionID, sessionID)
            XCTAssertEqual(request.joinRequest.clientDetails, SystemEnvironment.clientDetails)
            XCTAssertFalse(request.joinRequest.subscriberSdp.isEmpty)
            XCTAssertTrue(request.joinRequest.fastReconnect)
            XCTAssertEqual(request.joinRequest.token, token)
            XCTAssertEqual(request.joinRequest.reconnectDetails.reconnectAttempt, 11)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].trackType, .audio)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[0].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].trackType, .video)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[1].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].trackType, .screenShare)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[2].muted)
            XCTAssertEqual(sortedSubscriptions[0].userID, "0")
            XCTAssertEqual(sortedSubscriptions[0].sessionID, "0")
            XCTAssertEqual(sortedSubscriptions[0].trackType, .video)
            XCTAssertEqual(sortedSubscriptions[1].userID, "1")
            XCTAssertEqual(sortedSubscriptions[1].sessionID, "1")
            XCTAssertEqual(sortedSubscriptions[1].trackType, .audio)
            XCTAssertEqual(sortedSubscriptions[2].userID, "2")
            XCTAssertEqual(sortedSubscriptions[2].sessionID, "2")
            XCTAssertEqual(sortedSubscriptions[2].trackType, .screenShare)
            XCTAssertEqual(request.joinRequest.reconnectDetails.strategy, .fast)
            XCTAssertTrue(request.joinRequest.reconnectDetails.fromSfuID.isEmpty)
            XCTAssertTrue(request.joinRequest.reconnectDetails.previousSessionID.isEmpty)
        }
    }

    func test_transition_fromFastReconnectedSFUConnected_triggersRestartICEOnPeerConnections() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())

        /// We manually trigger the peerConnection configuration to allow us to test what will happen to
        /// the existing connections.
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()

        var response = Stream_Video_Sfu_Event_JoinResponse()
        let participantBuilder: () -> Stream_Video_Sfu_Models_Participant = {
            var result = Stream_Video_Sfu_Models_Participant()
            result.sessionID = .unique
            result.userID = .unique
            result.name = .unique
            result.publishedTracks = [.video]
            result.isSpeaking = false
            result.isDominantSpeaker = false
            result.connectionQuality = .good
            result.joinedAt = .init(timeIntervalSince1970: 1)
            result.audioLevel = 10
            return result
        }
        response.callState.participants = [
            participantBuilder(),
            participantBuilder(),
            participantBuilder()
        ]
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .fastReconnected,
            expectedTarget: .joined,
            subject: subject
        ) { [mockCoordinatorStack] in
            let publisher = await $0.context.coordinator?.stateAdapter.publisher
            let subscriber = await $0.context.coordinator?.stateAdapter.subscriber
            XCTAssertEqual((publisher as? MockRTCPeerConnectionCoordinator)?.timesCalled(.restartICE), 1)
            XCTAssertEqual((subscriber as? MockRTCPeerConnectionCoordinator)?.timesCalled(.restartICE), 0)
            XCTAssertEqual(mockCoordinatorStack?.webRTCAuthenticator.timesCalled(.waitForConnect), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromFastReconnectedWithSFUConnected_reportsTelemetry() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .fastReconnected,
            expectedTarget: .joined,
            subject: subject
        ) { _ in }

        cancellable.cancel()

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID, unifiedSessionId)

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTFail()
        case let .reconnection(reconnection):
            XCTAssertEqual(reconnection.strategy, .fast)
        case .none:
            XCTFail()
        }
    }

    // MARK: - transition from migrated

    func test_transition_fromMigratedWithoutCoordinator_updatesReconnectionStategy() async throws {
        /// Only the ``.rejoin`` strategy is valid during the rejoin flow.
        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: .joining(.init(reconnectionStrategy: .unknown))
        ) { XCTAssertEqual($0.context.reconnectionStrategy, .rejoin) }
    }

    func test_transition_fromMigratedWithoutSFUAdapter_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: .joining(.init(
                coordinator: mockCoordinatorStack.coordinator,
                reconnectionStrategy: .rejoin
            ))
        ) { _ in }
    }

    func test_transition_fromMigrated_sendsExpectedJoinRequest() async throws {
        throw XCTSkip("To be fixed")
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        let mockRTCCoordinator = try MockRTCPeerConnectionCoordinator(
            sessionId: "stub-session-id",
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        mockRTCCoordinator?.stub(for: .mid, with: "test-mid")
        let mockTrack = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .peerConnectionFactory
            .mockAudioTrack()
        mockTrack.isEnabled = true
        mockRTCCoordinator?.stub(for: .localTrack, with: mockTrack)
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = mockRTCCoordinator
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = mockRTCCoordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter.enqueue { _ in
                [
                    "0": .dummy(id: "0", hasVideo: true, hasAudio: false, isScreenSharing: false),
                    "1": .dummy(id: "1", hasVideo: false, hasAudio: true, isScreenSharing: false),
                    "2": .dummy(id: "2", hasVideo: false, hasAudio: false, isScreenSharing: true)
                ]
            }

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let request = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_SfuRequest.self,
                    for: .sendMessage
                )?.first
            )
            let sessionID = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            let token = await mockCoordinatorStack?.coordinator.stateAdapter.token
            let sortedSubscriptions = request.joinRequest.reconnectDetails.subscriptions.sorted { $0.userID < $1.userID }
            XCTAssertEqual(request.joinRequest.sessionID, sessionID)
            XCTAssertEqual(request.joinRequest.clientDetails, SystemEnvironment.clientDetails)
            XCTAssertFalse(request.joinRequest.subscriberSdp.isEmpty)
            XCTAssertFalse(request.joinRequest.fastReconnect)
            XCTAssertEqual(request.joinRequest.token, token)
            XCTAssertEqual(request.joinRequest.reconnectDetails.reconnectAttempt, 11)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[0].trackType, .audio)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[0].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[1].trackType, .video)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[1].muted)
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].mid, "test-mid")
            XCTAssertEqual(request.joinRequest.reconnectDetails.announcedTracks[2].trackType, .screenShare)
            XCTAssertFalse(request.joinRequest.reconnectDetails.announcedTracks[2].muted)
            XCTAssertEqual(sortedSubscriptions[0].userID, "0")
            XCTAssertEqual(sortedSubscriptions[0].sessionID, "0")
            XCTAssertEqual(sortedSubscriptions[0].trackType, .video)
            XCTAssertEqual(sortedSubscriptions[1].userID, "1")
            XCTAssertEqual(sortedSubscriptions[1].sessionID, "1")
            XCTAssertEqual(sortedSubscriptions[1].trackType, .audio)
            XCTAssertEqual(sortedSubscriptions[2].userID, "2")
            XCTAssertEqual(sortedSubscriptions[2].sessionID, "2")
            XCTAssertEqual(sortedSubscriptions[2].trackType, .screenShare)
            XCTAssertEqual(request.joinRequest.reconnectDetails.strategy, .migrate)
            XCTAssertEqual(request.joinRequest.reconnectDetails.fromSfuID, "test-sfu")
            XCTAssertTrue(request.joinRequest.reconnectDetails.previousSessionID.isEmpty)
        }
    }

    func test_transition_fromMigrated_increasesReconnectAttempts() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { XCTAssertEqual($0.context.reconnectAttempts, 12) }
    }

    func test_transition_fromMigrated_doesNotCreateSFUEventObserver() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        let sfuEventAdapter = SFUEventAdapter(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        subject.context.sfuEventObserver = sfuEventAdapter

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] target in
            XCTAssertTrue(
                target.context.sfuEventObserver === sfuEventAdapter
            )
            XCTAssertTrue(
                target.context.sfuEventObserver?.sfuAdapter === mockCoordinatorStack?.sfuStack.adapter
            )
        }
    }

    func test_transition_fromMigrated_updatesReconnectAttemptsOnStatsAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        subject.context.sfuEventObserver = SFUEventAdapter(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        let statsAdapter = MockWebRTCStatsAdapter()
        await subject
            .context
            .coordinator?
            .stateAdapter
            .set(statsAdapter: statsAdapter)

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                statsAdapter.reconnectAttempts,
                target.context.reconnectAttempts
            )
        }
    }

    func test_transition_fromMigrated_joinResponseReceiveTimeouts() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertEqual(
                (target.context.flowError as? ClientError)?.localizedDescription,
                "Operation timed out"
            )
        }
    }

    func test_transition_fromMigratedReceivesJoinResponse_updatesCallSettingsOnStateAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            let publisher = await target.context.coordinator?.stateAdapter.publisher
            let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
            XCTAssertEqual(mockPublisher.timesCalled(.didUpdateCallSettings), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigratedReceivesJoinResponse_sendsHealthCheck() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let webSocketEngine = try XCTUnwrap(mockCoordinatorStack?.sfuStack.webSocket.mockEngine)
            let requests = try XCTUnwrap(
                webSocketEngine.recordedInputPayload(
                    Stream_Video_Sfu_Event_HealthCheckRequest.self,
                    for: .sendMessage
                )
            )
            XCTAssertEqual(requests.count, 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigratedSFUNotConnected_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in XCTAssertTrue(target.context.flowError is ClientError) }
        cancellable.cancel()
    }

    func test_transition_fromMigrated_configuresPeerConnections() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .joined,
            subject: subject
        ) {
            let publisher = await $0.context.coordinator?.stateAdapter.publisher
            let subscriber = await $0.context.coordinator?.stateAdapter.subscriber
            XCTAssertNotNil(publisher)
            XCTAssertNotNil(subscriber)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigrated_configuresAudioSession() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .joined,
            subject: subject
        ) {
            let audioSession = await $0.context.coordinator?.stateAdapter.audioSession
            XCTAssertNotNil(audioSession?.delegate)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigratedSFUConnected_updatesParticipants() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())

        var response = Stream_Video_Sfu_Event_JoinResponse()
        let participantBuilder: () -> Stream_Video_Sfu_Models_Participant = {
            var result = Stream_Video_Sfu_Models_Participant()
            result.sessionID = .unique
            result.userID = .unique
            result.name = .unique
            result.publishedTracks = [.video]
            result.isSpeaking = false
            result.isDominantSpeaker = false
            result.connectionQuality = .good
            result.joinedAt = .init(timeIntervalSince1970: 1)
            result.audioLevel = 10
            return result
        }
        response.callState.participants = [
            participantBuilder(),
            participantBuilder(),
            participantBuilder()
        ]
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .joined,
            subject: subject
        ) { [mockCoordinatorStack] target in
            let participants = await target.context.coordinator?.stateAdapter.participants
            XCTAssertEqual(participants?.count, 3)
            XCTAssertEqual(mockCoordinatorStack?.webRTCAuthenticator.timesCalled(.waitForConnect), 1)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigratedReceivesJoinResponse_updateFastReconnectDeadlineSeconds() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = 22
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(response)),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .joined,
            subject: subject
        ) { target in
            XCTAssertEqual(target.context.fastReconnectDeadlineSeconds, 22)
        }
        cancellable.cancel()
    }

    func test_transition_fromMigratedWithSFUConnected_reportsTelemetry() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectAttempts = 11
        subject.context.migratingFromSFU = "test-sfu"
        let unifiedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .unifiedSessionId
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.webRTCAuthenticator.stubbedFunction[.waitForConnect] = Result<Void, Error>.success(())
        let cancellable = receiveEvent(
            .sfuEvent(.joinResponse(Stream_Video_Sfu_Event_JoinResponse())),
            every: 0.3
        )

        try await assertTransition(
            from: .migrated,
            expectedTarget: .joined,
            subject: subject
        ) { _ in }

        cancellable.cancel()

        let mockSignalService = try XCTUnwrap(mockCoordinatorStack?.sfuStack.service)
        await fulfillment { mockSignalService.sendStatsWasCalledWithRequest?.telemetry != nil }
        let telemetry = try XCTUnwrap(mockSignalService.sendStatsWasCalledWithRequest?.telemetry)
        XCTAssertEqual(mockSignalService.sendStatsWasCalledWithRequest?.unifiedSessionID, unifiedSessionId)

        switch telemetry.data {
        case .connectionTimeSeconds:
            XCTFail()
        case let .reconnection(reconnection):
            XCTAssertEqual(reconnection.strategy, .migrate)
        case .none:
            XCTFail()
        }
    }

    // MARK: - Private helpers

    private func assertTransition(
        from: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        subject: WebRTCCoordinator.StateMachine.Stage,
        validator: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let transitionExpectation =
            expectation(description: "Stage id:\(subject.id) is expected to transition to id:\(expectedTarget).")
        subject.transition = { [validator] target in
            guard target.id == expectedTarget else {
                transitionExpectation
                    .expectationDescription =
                    "Stage id:\(subject.id) is expected to transition to id:\(expectedTarget) but instead it was transition to id:\(target.id)."
                return
            }
            Task {
                do {
                    try await validator(target)
                    transitionExpectation.fulfill()
                } catch {
                    XCTFail(file: file, line: line)
                }
            }
        }
        _ = subject.transition(from: .init(id: from, context: subject.context))

        await fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
    }

    private func receiveEvent(
        _ event: WrappedEvent,
        every timeInterval: TimeInterval
    ) -> AnyCancellable {
        Foundation
            .Timer
            .publish(every: timeInterval, on: .main, in: .default)
            .autoconnect()
            .sink { [mockCoordinatorStack] _ in mockCoordinatorStack?.sfuStack.receiveEvent(event) }
    }
}
