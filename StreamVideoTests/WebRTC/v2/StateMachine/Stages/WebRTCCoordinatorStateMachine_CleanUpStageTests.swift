//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_CleanUpStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = Set(
        WebRTCCoordinator
            .StateMachine
            .Stage
            .ID
            .allCases
            .filter { $0 != .idle && $0 != subject.id }
    )
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .cleanUp(.init())
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init(
        videoConfig: Self.videoConfig
    )

    // MARK: - Lifecycle

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
        XCTAssertEqual(subject.id, .cleanUp)
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

    func test_transition_withoutCoordinator_transitionsToError() async throws {
        try await assertTransition(
            from: .disconnected,
            expectedTarget: .error,
            subject: subject
        ) { _ in }
    }

    func test_transition_cleanUpForReconnectionWasCalledOnStateAdapter() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        try await mockCoordinatorStack.coordinator.stateAdapter.configurePeerConnections()
        let publisher = await mockCoordinatorStack.coordinator.stateAdapter.publisher as? MockRTCPeerConnectionCoordinator
        let subscriber = await mockCoordinatorStack.coordinator.stateAdapter.subscriber as? MockRTCPeerConnectionCoordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(statsAdapter: MockWebRTCStatsAdapter())
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(ownCapabilities: [OwnCapability.blockUsers])
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .enqueue { _ in [.unique: .dummy()] }
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(participantsCount: 10)
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(participantPins: [PinInfo(isLocal: true, pinnedAt: .init())])
        mockCoordinatorStack
            .sfuStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.sfuAdapter)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.publisher)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.subscriber)
        await assertNilAsync(await mockCoordinatorStack.coordinator.stateAdapter.statsAdapter)
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.sessionID, "")
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.token, "")
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.ownCapabilities, [])
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.participants, [:])
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.participantsCount, 0)
        await assertEqualAsync(await mockCoordinatorStack.coordinator.stateAdapter.participantPins, [])

        XCTAssertEqual(publisher?.timesCalled(.close), 1)
        XCTAssertEqual(subscriber?.timesCalled(.close), 1)
        XCTAssertEqual(mockCoordinatorStack.sfuStack.webSocket.timesCalled(.disconnectAsync), 1)
    }

    func test_transition_contextWasReset() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.sfuEventObserver = .init(
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter,
            stateAdapter: mockCoordinatorStack.coordinator.stateAdapter
        )
        subject.context.reconnectAttempts = 10
        subject.context.currentSFU = .unique
        subject.context.fastReconnectDeadlineSeconds = 100
        subject.context.reconnectionStrategy = .rejoin
        subject.context.disconnectionSource = .userInitiated
        subject.context.flowError = ClientError()
        subject.context.isRejoiningFromSessionID = .unique
        subject.context.migratingFromSFU = .unique
        subject.context.migrationStatusObserver = .init(
            migratingFrom: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.previousSessionPublisher = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.previousSessionSubscriber = try MockRTCPeerConnectionCoordinator(
            peerType: .subscriber,
            sfuAdapter: mockCoordinatorStack.sfuStack.adapter
        )
        subject.context.previousSFUAdapter = mockCoordinatorStack.sfuStack.adapter

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        XCTAssertTrue(subject.context.coordinator === mockCoordinatorStack.coordinator)
        XCTAssertNil(subject.context.sfuEventObserver)
        XCTAssertEqual(subject.context.reconnectAttempts, 0)
        XCTAssertTrue(subject.context.currentSFU.isEmpty)
        XCTAssertEqual(subject.context.fastReconnectDeadlineSeconds, 0)
        XCTAssertEqual(subject.context.reconnectionStrategy, .unknown)
        XCTAssertNil(subject.context.disconnectionSource)
        XCTAssertNil(subject.context.flowError)
        XCTAssertNil(subject.context.isRejoiningFromSessionID)
        XCTAssertTrue(subject.context.migratingFromSFU.isEmpty)
        XCTAssertNil(subject.context.migrationStatusObserver)
        XCTAssertNil(subject.context.previousSessionPublisher)
        XCTAssertNil(subject.context.previousSessionSubscriber)
        XCTAssertNil(subject.context.previousSFUAdapter)
    }

    func test_transition_withoutCoordinator_transitionsToIdle() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        try await assertTransition(
            from: .disconnected,
            expectedTarget: .idle,
            subject: subject
        ) { _ in }
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
                    "Stage id:\(subject.id) is expected to transition to id:\(expectedTarget) but landed on id:\(target.id)"
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

    // MARK: - Private helpers

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
