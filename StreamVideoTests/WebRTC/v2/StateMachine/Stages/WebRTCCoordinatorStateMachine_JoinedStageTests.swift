//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import XCTest

final class WebRTCCoordinatorStateMachine_JoinedStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.joining]
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .joined(.init())

    // MARK: - Lifecycle

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
        XCTAssertEqual(subject.id, .joined)
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

    func test_transition_withoutCoordinator_transitionsToDisconnected() async throws {
        await assertTransitions(
            from: .joining,
            expectedTarget: .disconnected,
            transitionError: ClientError(),
            expectedTransitionsChain: [.disconnected]
        )
    }

    func test_transition_withoutCoordinatorWhileDisconnectedErrors_transitionsToError() async throws {
        await assertTransitions(
            from: .joining,
            expectedTarget: .error,
            transitionError: ClientError(),
            expectedTransitionsChain: [.disconnected, .error]
        )
    }

    func test_transition_withCoordinator_setReconnectionStrategyToRejoin() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.reconnectionStrategy = .unknown

        _ = subject.transition(from: .joining(.init()))

        await wait(for: 1)
        XCTAssertEqual(subject.context.reconnectionStrategy, .rejoin)
    }

    func test_transition_cleansUpContext() async throws {
        let publisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let subscriber = try MockRTCPeerConnectionCoordinator(
            peerType: .subscriber,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context = .init(
            coordinator: mockCoordinatorStack.coordinator,
            isRejoiningFromSessionID: .unique,
            migratingFromSFU: .unique,
            migrationStatusObserver: .init(migratingFrom: mockCoordinatorStack.sfuStack.adapter),
            previousSessionPublisher: publisher,
            previousSessionSubscriber: subscriber,
            previousSFUAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        _ = subject.transition(
            from: .joining(.init())
        )

        await wait(for: 1)
        XCTAssertNil(subject.context.previousSessionPublisher)
        XCTAssertNil(subject.context.previousSessionSubscriber)
        XCTAssertNil(subject.context.previousSFUAdapter)
        XCTAssertTrue(subject.context.migratingFromSFU.isEmpty)
        XCTAssertNil(subject.context.isRejoiningFromSessionID)
        XCTAssertNil(subject.context.migrationStatusObserver)
        XCTAssertEqual(publisher?.timesCalled(.close), 1)
        XCTAssertEqual(subscriber?.timesCalled(.close), 1)
    }

    // MARK: observeMigrationStatusIfRequired

    func test_transition_withoutMigrationStatusObserver_disconnectWasNotCalledOnPreviousSFUWebSocket() async throws {
        subject.context.previousSFUAdapter = mockCoordinatorStack.sfuStack.adapter

        _ = subject.transition(from: .joining(subject.context))

        XCTAssertEqual(mockCoordinatorStack.sfuStack.webSocket.timesCalled(.disconnect), 0)
    }

    func test_transition_withMigrationStatusObserverThatTimesOut_updatesReconnectionStrategyAndThrowsError() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.previousSFUAdapter = mockCoordinatorStack.sfuStack.adapter
        subject.context.migrationStatusObserver = .init(migratingFrom: mockCoordinatorStack.sfuStack.adapter)

        await assertTransitions(
            from: .joining,
            expectedTarget: .disconnected,
            expectedTransitionsChain: [.disconnected]
        )

        XCTAssertEqual(mockCoordinatorStack.sfuStack.webSocket.timesCalled(.disconnect), 0)
        XCTAssertEqual(subject.context.reconnectionStrategy, .rejoin)
        XCTAssertEqual(
            (subject.context.flowError as? ClientError)?.localizedDescription,
            "Migration from hostname:https://getstream.io failed after 5.0\nwhere we didn\'t receive a ParticipantMigrationComplete\nevent."
        )
    }

    func test_transition_withMigrationStatusObserverThatReceivedMigrationCompelete_disconnectWasCalledOnPreviousSFUAdapter(
    ) async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.previousSFUAdapter = mockCoordinatorStack.sfuStack.adapter
        mockCoordinatorStack.sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        let migrationStatusObserver = WebRTCMigrationStatusObserver(
            migratingFrom: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.migrationStatusObserver = migrationStatusObserver
        let cancellable = receiveEvent(
            .sfuEvent(
                .participantMigrationComplete(
                    Stream_Video_Sfu_Event_ParticipantMigrationComplete()
                )
            ),
            every: 0.1
        )

        _ = subject.transition(from: .joining(subject.context))

        await fulfillment { [mockCoordinatorStack] in
            mockCoordinatorStack?.sfuStack.webSocket.timesCalled(.disconnectAsync) == 1
        }
        cancellable.cancel()
    }

    // MARK: observeInternetConnection

    func test_transition_internetConnectionChangesToNotAvailable_transitionsToDisconnectCorrectlyConfigured() async {
        subject.context.fastReconnectDeadlineSeconds = 12

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.unavailable)
            }
        ) { target in
            switch target.context.reconnectionStrategy {
            case let .fast(_, deadline):
                XCTAssertEqual(deadline, 12)
            default:
                XCTFail()
            }
            XCTAssertEqual(
                target.context.disconnectionSource,
                .serverInitiated(
                    error: .NetworkError(
                        "Not available"
                    )
                )
            )
        }
    }

    func test_transition_internetConnectionChanges_traceWasCalledOnStatsAdapter() async {
        let statsAdapter = MockWebRTCStatsAdapter()

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?
                    .coordinator
                    .stateAdapter
                    .set(statsAdapter: statsAdapter)

                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.unavailable)
            }
        ) { _ in
            do {
                let trace = try XCTUnwrap(statsAdapter.recordedInputPayload(WebRTCTrace.self, for: .trace)?.first)
                XCTAssertEqual(trace.tag, "network.state.offline")
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    // MARK: observeForSubscriptionUpdates

    func test_transition_participantsUpdated_updateSubscriptionsWasCalledOnSFU() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await assertResultAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?.coordinator.stateAdapter.enqueue { _ in
                    [
                        sessionId: .dummy(id: sessionId, hasVideo: true),
                        "0": .dummy(hasVideo: true),
                        "1": .dummy(hasVideo: true)
                    ]
                }
            }
        ) { [mockCoordinatorStack] expectation in
            let request = try? XCTUnwrap(mockCoordinatorStack?.sfuStack.service.updateSubscriptionsWasCalledWithRequest)
            XCTAssertEqual(request?.tracks.count, 2)
            expectation.fulfill()
        }
    }

    func test_transition_participantsUpdated_withoutChanges_updateSubscriptionsWasCalledOnSFUOnlyOnce() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        let participantsUpdate: [String: CallParticipant] = [
            sessionId: .dummy(id: sessionId, hasVideo: true),
            "0": .dummy(hasVideo: true),
            "1": .dummy(hasVideo: true)
        ]

        await assertResultAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?.coordinator.stateAdapter.enqueue { _ in
                    participantsUpdate
                }

                await self.wait(for: 0.5)

                await mockCoordinatorStack?.coordinator.stateAdapter.enqueue { _ in
                    participantsUpdate
                }
            }
        ) { [mockCoordinatorStack] expectation in
            XCTAssertEqual(mockCoordinatorStack?.sfuStack.service.timesCalled(.updateSubscriptions), 1)
            expectation.fulfill()
        }
    }

    func test_transition_participantsUpdatedUpdateSubscriptionsFails_noReconnectionOccurs() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        var response = Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse()
        response.error = .init()
        response.error.code = .requestValidationFailed
        response.error.message = "update subscriptions error"
        mockCoordinatorStack?
            .sfuStack
            .service
            .stub(for: .updateSubscriptions, with: response)

        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await assertTransitionAfterTrigger(
            expectedTarget: nil
        ) { [mockCoordinatorStack] in
            await mockCoordinatorStack?.coordinator.stateAdapter.enqueue { _ in
                [
                    sessionId: .dummy(id: sessionId, hasVideo: true),
                    "0": .dummy(hasVideo: true),
                    "1": .dummy(hasVideo: true)
                ]
            }
        } validationHandler: { _ in }

        let request = try? XCTUnwrap(mockCoordinatorStack.sfuStack.service.updateSubscriptionsWasCalledWithRequest)
        XCTAssertEqual(request?.tracks.count, 2)
    }

    // MARK: observeConnection

    func test_transition_webSocketDisconnectsWithSFUErrorWithShouldRetryTrue_transitionsToDisconnectCorrectlyConfigured() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.fastReconnectDeadlineSeconds = 12
        var sfuError = Stream_Video_Sfu_Models_Error()
        sfuError.shouldRetry = true
        let clientError = ClientError(with: sfuError)

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?.sfuStack.setConnectionState(
                    to: .disconnected(
                        source: .serverInitiated(error: clientError)
                    )
                )
            }
        ) { target in
            switch target.context.reconnectionStrategy {
            case let .fast(_, deadline):
                XCTAssertEqual(deadline, 12)
            default:
                XCTFail()
            }
            XCTAssertEqual(
                target.context.disconnectionSource,
                .serverInitiated(error: clientError)
            )
        }
    }

    func test_transition_webSocketDisconnectsWithSFUErrorWithShouldRetryFalse_transitionsToDisconnectCorrectlyConfigured() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.fastReconnectDeadlineSeconds = 12
        var sfuError = Stream_Video_Sfu_Models_Error()
        sfuError.shouldRetry = false
        let clientError = ClientError(with: sfuError)

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?.sfuStack.setConnectionState(
                    to: .disconnected(
                        source: .serverInitiated(error: clientError)
                    )
                )
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .rejoin)
            XCTAssertEqual(
                target.context.disconnectionSource,
                .serverInitiated(error: clientError)
            )
        }
    }

    // MARK: observeCallEndedEvent

    func test_transition_callEndedReceived_landsOnLeaving() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .leaving,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.callEnded(Stream_Video_Sfu_Event_CallEnded())))
            }
        ) { _ in }
    }

    // MARK: observeMigrationEvent

    func test_transition_sfuErrorWithReconnectionStrategyMigrateReceived_landsOnDisconnected() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .migrate
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .migrate)
        }
    }

    func test_transition_sfuErrorWithReconnectionStrategyRejoinReceived_reconnectionStrategyUpdated() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .rejoin
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .rejoin)
        }
    }

    func test_transition_sfuErrorWithReconnectionStrategyFastReceived_reconnectionStrategyUpdated() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.fastReconnectDeadlineSeconds = 12

        await assertTransitionAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .fast
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { target in
            switch target.context.reconnectionStrategy {
            case let .fast(_, deadline):
                XCTAssertEqual(deadline, 12)
            default:
                XCTFail()
            }
        }
    }

    func test_transition_goAwayReceived_landsOnDisconnected() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.goAway(Stream_Video_Sfu_Event_GoAway())))
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .migrate)
        }
    }

    // MARK: observeDisconnectEvent

    func test_transition_sfuErrorWithReconnectionStrategyDisconnectReceived_landsOnLeaving() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .leaving,
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .disconnect
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { _ in }
    }

    // MARK: observeDisconnectEvent

    func test_transition_sfuErrorWithErrorCodeParticipantLostSignal_landsOnDisconnectedWithReconenctionStrategyFastReconnect(
    ) async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .unspecified
                error.error.code = .participantSignalLost
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { stage in
            switch stage.context.reconnectionStrategy {
            case .fast:
                break
            default:
                XCTFail()
            }
        }
    }

    // MARK: - observeHealthCheckResponses

    func test_transition_hasNotReceivedHealthCheckResponseForTheRequiredTime_landsOnDisconnectedWithReconenctionStrategyFastReconnect(
    ) async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.lastHealthCheckReceivedAt = .init()
        subject.context.webSocketHealthTimeout = 1

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: {}
        ) { stage in
            switch stage.context.reconnectionStrategy {
            case .fast:
                break
            default:
                XCTFail()
            }
        }
    }

    func test_transition_hasReceivedHealthCheckResponseForTheRequiredTime_remainsOnJoined() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let lastHealthCheckReceivedAt = Date()
        subject.context.lastHealthCheckReceivedAt = lastHealthCheckReceivedAt
        subject.context.webSocketHealthTimeout = 5

        await assertResultAfterTrigger {
            self.mockCoordinatorStack.sfuStack.receiveEvent(.sfuEvent(.healthCheckResponse(.init())))
        } validationHandler: { expectation in
            guard
                let currentLastHealthCheckReceivedAt = self.subject.context.lastHealthCheckReceivedAt,
                currentLastHealthCheckReceivedAt > lastHealthCheckReceivedAt,
                self.subject.context.reconnectionStrategy == .rejoin
            else {
                return
            }
            expectation.fulfill()
        }
    }

    // MARK: observePreferredReconnectionStrategy

    func test_transition_sfuErrorWithReconnectionStrategyFastReceived_updatesContext() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.fastReconnectDeadlineSeconds = 12

        await assertTransitionAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .fast
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { target in
            switch target.context.reconnectionStrategy {
            case let .fast(_, deadline):
                XCTAssertEqual(deadline, 12)
            default:
                XCTFail()
            }
        }
    }

    func test_transition_sfuErrorWithReconnectionStrategyRejoinReceived_updatesContext() async {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.fastReconnectDeadlineSeconds = 12

        await assertTransitionAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                var error = Stream_Video_Sfu_Event_Error()
                error.reconnectStrategy = .rejoin
                mockCoordinatorStack?
                    .sfuStack
                    .receiveEvent(.sfuEvent(.error(error)))
            }
        ) { target in
            XCTAssertEqual(target.context.reconnectionStrategy, .rejoin)
        }
    }

    // MARK: observePeerConnectionState

    func test_transition_publisherDisconnects_restartICEWasTriggeredOnPublisher() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let mockPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let subject = PassthroughSubject<Void, Never>()
        mockPublisher?.stub(for: \.disconnectedPublisher, with: subject.eraseToAnyPublisher())
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = mockPublisher
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { subject.send(()) },
            validationHandler: { stage in
                XCTAssertEqual(stage.context.reconnectionStrategy, .rejoin)
            }
        )
    }

    func test_transition_subscriberDisconnects_restartICEWasTriggeredOnSubscriber() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let mockSubscriber = try MockRTCPeerConnectionCoordinator(
            peerType: .subscriber,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let subject = PassthroughSubject<Void, Never>()
        mockSubscriber?.stub(for: \.disconnectedPublisher, with: subject.eraseToAnyPublisher())
        mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = mockSubscriber
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { subject.send(()) },
            validationHandler: { stage in
                XCTAssertEqual(stage.context.reconnectionStrategy, .rejoin)
            }
        )
    }

    // MARK: configureStatsCollectionAndDelivery

    func test_transition_sameSessionId_configuresStatsAdapter() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await stateAdapter.set(sfuAdapter: sfuAdapter)
        let sessionId = await stateAdapter.sessionID
        let unifiedSessionId = await stateAdapter.unifiedSessionId
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher
        let subscriber = await stateAdapter.subscriber
        let initialStatsAdapter = WebRTCStatsAdapter(
            sessionID: sessionId,
            unifiedSessionID: unifiedSessionId,
            isTracingEnabled: true,
            trackStorage: await stateAdapter.trackStorage
        )
        initialStatsAdapter.deliveryInterval = 12
        await stateAdapter.set(statsAdapter: initialStatsAdapter)
        subject.context.coordinator = mockCoordinatorStack.coordinator

        _ = subject.transition(from: .joining(subject.context))

        await wait(for: 1)
        let newStatsAdapter = await stateAdapter.statsAdapter
        XCTAssertEqual(newStatsAdapter?.deliveryInterval, 12)
        XCTAssertTrue(newStatsAdapter?.publisher === publisher)
        XCTAssertTrue(newStatsAdapter?.subscriber === subscriber)
        XCTAssertTrue(newStatsAdapter?.sfuAdapter === sfuAdapter)
        XCTAssertEqual(newStatsAdapter?.unifiedSessionID, unifiedSessionId)
    }

    func test_transition_differentSessionId_configuresStatsAdapter() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await stateAdapter.set(sfuAdapter: sfuAdapter)
        await stateAdapter.set(isTracingEnabled: true)
        let unifiedSessionId = await stateAdapter.unifiedSessionId
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher
        let subscriber = await stateAdapter.subscriber
        let initialStatsAdapter = WebRTCStatsAdapter(
            sessionID: .unique,
            unifiedSessionID: unifiedSessionId,
            isTracingEnabled: await stateAdapter.isTracingEnabled,
            trackStorage: await stateAdapter.trackStorage
        )
        initialStatsAdapter.deliveryInterval = 11
        await stateAdapter.set(statsAdapter: initialStatsAdapter)
        subject.context.coordinator = mockCoordinatorStack.coordinator

        _ = subject.transition(from: .joining(subject.context))

        await fulfillment {
            let newStatsAdapter = await stateAdapter.statsAdapter
            return newStatsAdapter !== initialStatsAdapter && newStatsAdapter?.deliveryInterval == 11
        }
        let newStatsAdapter = await stateAdapter.statsAdapter
        XCTAssertEqual(newStatsAdapter?.unifiedSessionID, initialStatsAdapter.unifiedSessionID)
        XCTAssertEqual(newStatsAdapter?.isTracingEnabled, initialStatsAdapter.isTracingEnabled)
        XCTAssertEqual(newStatsAdapter?.deliveryInterval, 11)
        XCTAssertTrue(newStatsAdapter?.publisher === publisher)
        XCTAssertTrue(newStatsAdapter?.subscriber === subscriber)
        XCTAssertTrue(newStatsAdapter?.sfuAdapter === sfuAdapter)
        XCTAssertEqual(newStatsAdapter?.unifiedSessionID, unifiedSessionId)
    }

    // MARK: observeIncomingVideoQualitySettings

    func test_transition_incomingVideoQualitySettingsUpdated_updateSubscriptionsWasCalledOnSFU() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await mockCoordinatorStack?.coordinator.stateAdapter.enqueue { _ in
            [
                sessionId: .dummy(id: sessionId),
                "0": .dummy(id: "0", hasVideo: true),
                "1": .dummy(id: "1", hasVideo: true)
            ]
        }
        let incomingVideoQualitySettings = IncomingVideoQualitySettings
            .disabled(group: .custom(sessionIds: ["0"]))

        await assertResultAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?
                    .coordinator
                    .setIncomingVideoQualitySettings(incomingVideoQualitySettings)
            }
        ) { [mockCoordinatorStack] expectation in
            let request = try? XCTUnwrap(mockCoordinatorStack?.sfuStack.service.updateSubscriptionsWasCalledWithRequest)
            XCTAssertEqual(request?.tracks.count, 1)
            expectation.fulfill()
        }
    }

    // MARK: - Private helpers

    private func assertTransitions(
        from: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        transitionError: Error? = nil,
        expectedTransitionsChain: [WebRTCCoordinator.StateMachine.Stage.ID],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        var transitions: [WebRTCCoordinator.StateMachine.Stage.ID] = []
        let transitionExpectation = expectation(description: "Expectation to land on id:\(expectedTarget).")
        subject.transition = {
            transitions.append($0.id)
            if $0.id == expectedTarget {
                transitionExpectation.fulfill()
            } else if let transitionError {
                throw transitionError
            }
        }

        _ = subject.transition(from: .init(id: from, context: subject.context))

        await fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
        XCTAssertEqual(transitions, expectedTransitionsChain)
    }

    private func assertTransitionAfterTrigger(
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID? = nil,
        trigger: @escaping @Sendable () async -> Void,
        validationHandler: @escaping @Sendable (WebRTCCoordinator.StateMachine.Stage) async -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = subject.transition(from: .joining(subject.context))

        let transitionExpectation: XCTestExpectation

        if let expectedTarget {
            transitionExpectation = expectation(
                description: "Expectation to land on id:\(expectedTarget)."
            )
        } else {
            transitionExpectation = expectation(
                description: "Expectation to remain in the id without transitions."
            )
            transitionExpectation.isInverted = true
        }

        subject.transition = { target in
            Task {
                if target.id == expectedTarget {
                    await validationHandler(target)
                    transitionExpectation.fulfill()
                } else if let expectedTarget {
                    transitionExpectation
                        .expectationDescription =
                        "Expectation to land on id:\(expectedTarget) but instead landed on id:\(target.id)."
                } else if expectedTarget == nil {
                    // If we expect no transition but one occurs we fulfil
                    // the expectation to propagate the error.
                    transitionExpectation.fulfill()
                }
            }
        }

        await withTaskGroup(of: Void.self) { [subject] group in
            group.addTask {
                await self.wait(for: 0.3)
                await trigger()
            }

            group.addTask {
                await self.fulfillment(of: [transitionExpectation], timeout: transitionExpectation.isInverted ? 2 : defaultTimeout)
                if transitionExpectation.isInverted {
                    await validationHandler(subject!)
                }
            }

            await group.waitForAll()
        }
    }

    private func assertResultAfterTrigger(
        trigger: @escaping @Sendable () async -> Void,
        validationHandler: @escaping @Sendable (XCTestExpectation) async -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = subject.transition(from: .joining(subject.context))
        await wait(for: 0.5)
        let resultExpectation = expectation(description: "Expectation for desired result to occur.")

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.wait(for: 0.2)
                await trigger()
                await self.wait(for: 0.3)
                await validationHandler(resultExpectation)
            }

            group.addTask {
                await self.fulfillment(of: [resultExpectation], timeout: defaultTimeout)
            }

            await group.waitForAll()
        }
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
