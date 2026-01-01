//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_DisconnectedStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [
        .connecting,
        .joining,
        .joined,
        .disconnected,
        .fastReconnecting,
        .fastReconnected,
        .rejoining,
        .migrated,
        .migrating
    ]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .disconnected(.init())
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )

    override func setUp() {
        super.setUp()
        mockCoordinatorStack.internetConnection.subject.send(.unknown)
    }

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        allOtherStages = nil
        validStages = nil
        subject = nil
        mockCoordinatorStack = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .disconnected)
    }

    // MARK: - willTransitionAway

    func test_willTransitionAway_disconnectionSourceAndFlowErrorAreCleanedUp() {
        subject.context.disconnectionSource = .userInitiated
        subject.context.flowError = ClientError()

        subject.willTransitionAway()

        XCTAssertNil(subject.context.disconnectionSource)
        XCTAssertNil(subject.context.flowError)
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

    func test_transition_cleansUpSFUEventObserverFromContext() async throws {
        subject.context.sfuEventObserver = .init(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )

        await assertTransitionAfterTrigger(trigger: {}) { target in
            XCTAssertNil(target.context.sfuEventObserver)
        }
    }

    func test_transition_cleansUpLastHealthCheckReceivedAt() async throws {
        subject.context.lastHealthCheckReceivedAt = .init()

        await assertTransitionAfterTrigger(trigger: {}) { target in
            XCTAssertNil(target.context.lastHealthCheckReceivedAt)
        }
    }

    func test_transition_cleansUpDisconnectionSource() async throws {
        subject.context.disconnectionSource = .noPongReceived

        await assertTransitionAfterTrigger(trigger: {}) { target in
            XCTAssertNil(target.context.disconnectionSource)
        }
    }

    func test_transition_scheduleStatsReportingWasCalled() async throws {
        let statsAdapter = MockWebRTCStatsAdapter()
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            statsAdapter: statsAdapter
        )

        await assertTransitionAfterTrigger(trigger: {}) { _ in
            XCTAssertEqual(statsAdapter.timesCalled(.scheduleStatsReporting), 1)
        }
    }

    func test_transition_SFUAdapterOnStatsAdapterIsNil() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            statsAdapter: WebRTCStatsAdapter(
                sessionID: .unique,
                unifiedSessionID: .unique,
                isTracingEnabled: true,
                trackStorage: mockCoordinatorStack.coordinator.stateAdapter.trackStorage
            )
        )

        await assertTransitionAfterTrigger(trigger: {}) { target in
            await self.assertNilAsync(
                await target.context.coordinator?.stateAdapter.statsAdapter?.sfuAdapter
            )
        }
    }

    func test_transition_flowErrorIsUnrecoverable_reconnectionStrategyChangesToDisconnected() {
        subject.context.reconnectionStrategy = .rejoin
        subject.context.flowError = APIError(
            code: 0,
            details: [],
            duration: "0",
            message: .unique,
            moreInfo: .unique,
            statusCode: 401,
            unrecoverable: true
        )

        _ = subject.transition(from: .connected(subject.context))

        XCTAssertEqual(subject.context.reconnectionStrategy, .disconnected)
    }

    // MARK: observeInternetConnection

    func test_transition_connectionRestoresWithDisconnectedStrategy_landsOnLeaving() async {
        subject.context.reconnectionStrategy = .disconnected

        await assertTransitionAfterTrigger(
            expectedTarget: .leaving,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithUnknownStrategyWithoutFlowError_landsOnLeaving() async {
        subject.context.reconnectionStrategy = .unknown

        await assertTransitionAfterTrigger(
            expectedTarget: .leaving,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithUnknownStrategyWithFlowError_landsOnError() async {
        subject.context.reconnectionStrategy = .unknown
        let error = ClientError()
        subject.context.flowError = error

        await assertTransitionAfterTrigger(
            expectedTarget: .error,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { target in
            XCTAssertTrue(
                ((target as? WebRTCCoordinator.StateMachine.Stage.ErrorStage)?.error as? ClientError) === error
            )
        }
    }

    func test_transition_connectionRestoresWithMigrateStrategy_landsOnMigrating() async {
        subject.context.reconnectionStrategy = .migrate

        await assertTransitionAfterTrigger(
            expectedTarget: .migrating,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithRejoinStrategy_landsOnRejoining() async {
        subject.context.reconnectionStrategy = .rejoin

        await assertTransitionAfterTrigger(
            expectedTarget: .rejoining,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithFastStrategyWithoutExpiredDeadline_landsOnFastReconnection() async throws {
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 10)
        let publisher =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(peerType: .publisher, sfuAdapter: mockCoordinatorStack.sfuStack.adapter))
        publisher.stub(for: \.isHealthy, with: true)
        let subscriber =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: mockCoordinatorStack.sfuStack.adapter
            ))
        subscriber.stub(for: \.isHealthy, with: true)
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.publisher] = publisher
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.subscriber] = subscriber
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()

        await assertTransitionAfterTrigger(
            expectedTarget: .fastReconnecting,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithFastStrategyPublisherNotHealthy_landsOnRejoin() async throws {
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 10)
        let publisher =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(peerType: .publisher, sfuAdapter: mockCoordinatorStack.sfuStack.adapter))
        publisher.stub(for: \.isHealthy, with: false)
        let subscriber =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: mockCoordinatorStack.sfuStack.adapter
            ))
        subscriber.stub(for: \.isHealthy, with: true)
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.publisher] = publisher
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.subscriber] = subscriber
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()

        await assertTransitionAfterTrigger(
            expectedTarget: .rejoining,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithFastStrategySubscriberNotHealthy_landsOnRejoin() async throws {
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 10)
        let publisher =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(peerType: .publisher, sfuAdapter: mockCoordinatorStack.sfuStack.adapter))
        publisher.stub(for: \.isHealthy, with: true)
        let subscriber =
            try XCTUnwrap(MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: mockCoordinatorStack.sfuStack.adapter
            ))
        subscriber.stub(for: \.isHealthy, with: false)
        await mockCoordinatorStack.coordinator.stateAdapter.set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.publisher] = publisher
        mockCoordinatorStack.rtcPeerConnectionCoordinatorFactory.stubbedBuildCoordinatorResult[.subscriber] = subscriber
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()

        await assertTransitionAfterTrigger(
            expectedTarget: .rejoining,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionRestoresWithFastStrategyWithExpiredDeadline_landsOnRejoining() async {
        subject.context.reconnectionStrategy = .fast(
            disconnectedSince: .init(timeIntervalSinceNow: -30),
            deadline: 10
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .rejoining,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in }
    }

    func test_transition_connectionDoesNotRestoreWithDisconnectionTimeout_landsOnError() async {
        subject.context.disconnectionTimeout = 1

        await assertTransitionAfterTrigger(
            expectedTarget: .error,
            trigger: {}
        ) { _ in }
    }

    func test_transition_connectionStateChanges_traceWasCalledOnstatsAdapter() async {
        subject.context.reconnectionStrategy = .disconnected
        let statsAdapter = MockWebRTCStatsAdapter()
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            statsAdapter: statsAdapter
        )

        await assertTransitionAfterTrigger(
            expectedTarget: .leaving,
            trigger: { [mockCoordinatorStack] in
                mockCoordinatorStack?
                    .internetConnection
                    .subject
                    .send(.available(.great))
            }
        ) { _ in
            XCTAssertEqual(
                statsAdapter.recordedInputPayload(WebRTCTrace.self, for: .trace)?.filter { $0.tag.hasPrefix("network.state") }
                    .count,
                1
            )
        }
    }

    // MARK: - Private helpers

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

    private func assertNilAsync<T>(
        _ expression: @autoclosure () async throws -> T?,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertNil(value, file: file, line: line)
    }
}
