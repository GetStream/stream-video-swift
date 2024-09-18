//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_DisconnectedStageTests: XCTestCase, @unchecked Sendable {

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
        .rejoining,
        .migrated
    ]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .disconnected(.init())
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init()

    override func setUp() {
        super.setUp()
        mockCoordinatorStack.internetConnection.subject.send(.unknown)
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

    func test_transition_SFUAdapterOnStatsReporterIsNil() async throws {
        await mockCoordinatorStack.coordinator.stateAdapter.set(
            statsReporter: WebRTCStatsReporter(
                sessionID: .unique
            )
        )

        await assertTransitionAfterTrigger(trigger: {}) { target in
            await self.assertNilAsync(
                await target.context.coordinator?.stateAdapter.statsReporter?.sfuAdapter
            )
        }
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

    func test_transition_connectionRestoresWithFastStrategyWithoutExpiredDeadline_landsOnFastReconnectin() async {
        subject.context.reconnectionStrategy = .fast(disconnectedSince: .init(), deadline: 10)

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

    // MARK: - Private helpers

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

    private func assertNilAsync<T>(
        _ expression: @autoclosure () async throws -> T?,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertNil(value, file: file, line: line)
    }
}
