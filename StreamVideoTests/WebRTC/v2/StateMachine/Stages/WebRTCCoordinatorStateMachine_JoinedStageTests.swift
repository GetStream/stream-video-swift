//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_JoinedStageTests: XCTestCase, @unchecked Sendable {

    private static var videoConfig: VideoConfig! = .dummy()

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
            "Migration from hostname:https://getstream.io failed after 1.0\nwhere we didn\'t receive a ParticipantMigrationComplete\nevent."
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
                await mockCoordinatorStack?.coordinator.stateAdapter.didUpdateParticipants([
                    sessionId: .dummy(id: sessionId, hasAudio: true),
                    "0": .dummy(hasAudio: true),
                    "1": .dummy(hasAudio: true)
                ])
            }
        ) { [mockCoordinatorStack] expectation in
            let request = try? XCTUnwrap(mockCoordinatorStack?.sfuStack.service.updateSubscriptionsWasCalledWithRequest)
            XCTAssertEqual(request?.tracks.count, 2)
            expectation.fulfill()
        }
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

    // MARK: observeCallSettingsUpdates

    func test_transition_callSettingsUpdatedAndPublisherThrowsError_transitionsToDisconnected() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()
        let publisher = await mockCoordinatorStack?.coordinator.stateAdapter.publisher
        let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)
        mockPublisher.stub(
            for: .didUpdateCallSettings,
            with: Result<Void, Error>.failure(ClientError())
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .disconnected,
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?
                    .coordinator
                    .stateAdapter
                    .set(callSettings: CallSettings(audioOn: true, videoOn: true))
            }
        ) { _ in }
    }

    func test_transition_callSettingsUpdated_publisherUpdated() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .configurePeerConnections()
        let publisher = await mockCoordinatorStack?.coordinator.stateAdapter.publisher
        let mockPublisher = try XCTUnwrap(publisher as? MockRTCPeerConnectionCoordinator)

        await assertResultAfterTrigger(
            trigger: { [mockCoordinatorStack] in
                await mockCoordinatorStack?
                    .coordinator
                    .stateAdapter
                    .set(callSettings: CallSettings(audioOn: true, videoOn: true))
            }
        ) { [mockPublisher] expectation in
            XCTAssertEqual(mockPublisher.timesCalled(.didUpdateCallSettings), 1)
            expectation.fulfill()
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

        await assertResultAfterTrigger(
            trigger: {
                subject.send(())
            }
        ) { expectation in
            XCTAssertEqual(mockPublisher?.timesCalled(.restartICE), 1)
            expectation.fulfill()
        }
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

        await assertResultAfterTrigger(
            trigger: {
                subject.send(())
            }
        ) { expectation in
            XCTAssertEqual(mockSubscriber?.timesCalled(.restartICE), 1)
            expectation.fulfill()
        }
    }

    // MARK: configureStatsCollectionAndDelivery

    func test_transition_sameSessionId_configuresStatsReporter() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await stateAdapter.set(sfuAdapter: sfuAdapter)
        let sessionId = await stateAdapter.sessionID
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher
        let subscriber = await stateAdapter.subscriber
        let initialStatsReporter = WebRTCStatsReporter(interval: 12, sessionID: sessionId)
        await stateAdapter.set(statsReporter: initialStatsReporter)
        subject.context.coordinator = mockCoordinatorStack.coordinator

        _ = subject.transition(from: .joining(subject.context))

        await wait(for: 1)
        let newStatsReporter = await stateAdapter.statsReporter
        XCTAssertEqual(newStatsReporter?.interval, 12)
        XCTAssertTrue(newStatsReporter?.publisher === publisher)
        XCTAssertTrue(newStatsReporter?.subscriber === subscriber)
        XCTAssertTrue(newStatsReporter?.sfuAdapter === sfuAdapter)
    }

    func test_transition_differentSessionId_configuresStatsReporter() async throws {
        let stateAdapter = mockCoordinatorStack.coordinator.stateAdapter
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter
        await stateAdapter.set(sfuAdapter: sfuAdapter)
        let sessionId = await stateAdapter.sessionID
        try await stateAdapter.configurePeerConnections()
        let publisher = await stateAdapter.publisher
        let subscriber = await stateAdapter.subscriber
        let initialStatsReporter = WebRTCStatsReporter(interval: 11, sessionID: .unique)
        await stateAdapter.set(statsReporter: initialStatsReporter)
        subject.context.coordinator = mockCoordinatorStack.coordinator

        _ = subject.transition(from: .joining(subject.context))

        await fulfillment {
            let newStatsReporter = await stateAdapter.statsReporter
            return newStatsReporter !== initialStatsReporter && newStatsReporter?.interval == 11
        }
        let newStatsReporter = await stateAdapter.statsReporter
        XCTAssertEqual(newStatsReporter?.interval, 11)
        XCTAssertTrue(newStatsReporter?.publisher === publisher)
        XCTAssertTrue(newStatsReporter?.subscriber === subscriber)
        XCTAssertTrue(newStatsReporter?.sfuAdapter === sfuAdapter)
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
        trigger: @escaping () async -> Void,
        validationHandler: @escaping (WebRTCCoordinator.StateMachine.Stage) async -> Void,
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
                }
            }
        }

        await withTaskGroup(of: Void.self) { [subject] group in
            group.addTask {
                await self.wait(for: 0.3)
                await trigger()
            }

            group.addTask {
                await self.fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
                if transitionExpectation.isInverted {
                    await validationHandler(subject!)
                }
            }

            await group.waitForAll()
        }
    }

    private func assertResultAfterTrigger(
        trigger: @escaping () async -> Void,
        validationHandler: @escaping (XCTestExpectation) async -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = subject.transition(from: .joining(subject.context))
        await wait(for: 0.5)
        let resultExpectation = expectation(description: "Expectation to for desired result to occur.")

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
