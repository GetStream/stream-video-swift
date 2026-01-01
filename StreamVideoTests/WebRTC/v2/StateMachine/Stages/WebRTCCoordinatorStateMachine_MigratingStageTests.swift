//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_MigratingStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.disconnected]
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .migrating(.init())

    // MARK: - Lifecycle

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    override func tearDown() {
        allOtherStages = nil
        mockCoordinatorStack = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .migrating)
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

    func test_transition_withoutCoordinator_transitionsToDisconnected() async {
        await assertTransitions(
            from: .disconnected,
            expectedTarget: .disconnected,
            expectedTransitionsChain: [.disconnected]
        )
    }

    func test_transition_sfuEventObservationWasStopped() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let sfuEventObserver = SFUEventAdapter(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        subject.context.sfuEventObserver = sfuEventObserver
        let currentSFU = String.unique
        subject.context.currentSFU = currentSFU
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()

        try await assertTransition(
            from: .disconnected,
            expectedTarget: .migrated,
            subject: subject
        ) { _ in XCTAssertFalse(sfuEventObserver.isActive) }
    }

    func test_transition_contextWasSetCorrectly() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.sfuEventObserver = .init(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        let currentSFU = String.unique
        subject.context.currentSFU = currentSFU
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()
        let publisher = await mockCoordinatorStack.coordinator.stateAdapter.publisher
        let subscriber = await mockCoordinatorStack.coordinator.stateAdapter.subscriber
        let sfuAdapter = mockCoordinatorStack.sfuStack.adapter

        try await assertTransition(
            from: .disconnected,
            expectedTarget: .migrated,
            subject: subject
        ) { target in
            XCTAssertTrue(target.context.previousSessionPublisher === publisher)
            XCTAssertTrue(target.context.previousSessionSubscriber === subscriber)
            XCTAssertTrue(target.context.previousSFUAdapter === sfuAdapter)
            XCTAssertNil(target.context.sfuEventObserver)
            XCTAssertEqual(target.context.migratingFromSFU, currentSFU)
            XCTAssertTrue(target.context.currentSFU.isEmpty)
        }
    }

    func test_transition_cleanUpForReconnectionWasCalledOnStateAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        _ = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.sfuAdapter)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.publisher)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.subscriber)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.statsAdapter)
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.token, "")
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

    private func assertNilAsync<T>(
        _ expression: @autoclosure () async throws -> T?,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        XCTAssertNil(value, file: file, line: line)
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
}
