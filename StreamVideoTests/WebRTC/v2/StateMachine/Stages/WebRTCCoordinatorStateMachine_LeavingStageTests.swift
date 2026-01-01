//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_LeavingStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.joined, .disconnected, .connected, .connecting]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .leaving(.init())
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
        XCTAssertEqual(subject.id, .leaving)
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
        try await assertTransition(
            from: .disconnected,
            expectedTarget: .error,
            subject: subject
        ) { _ in }
    }

    func test_transition_WithoutSFUAdapter_transitionsToCleanUp() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator

        try await assertTransition(
            from: .joined,
            expectedTarget: .cleanUp,
            subject: subject
        ) { _ in }
    }

    func test_transition_sfuAdapterIsNotConnected_sendLeaveRequestAndDisconnecteWereNotCalled() async {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)

        _ = subject.transition(from: .disconnected(subject.context))
        await wait(for: 0.5)

        let webSocket = mockCoordinatorStack.sfuStack.webSocket
        XCTAssertEqual(webSocket.mockEngine.timesCalled(.sendMessage), 0)
        XCTAssertEqual(webSocket.timesCalled(.disconnectAsync), 0)
    }

    func test_transition_sfuAdapterIsConnected_sendLeaveRequestAndDisconnecteWereCalled() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        let sessionId = try await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .$sessionID
            .filter { !$0.isEmpty }
            .nextValue()
        await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .set(sfuAdapter: mockCoordinatorStack.sfuStack.adapter)
        mockCoordinatorStack
            .sfuStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))

        _ = subject.transition(from: .joined(subject.context))
        await wait(for: 1)

        let webSocket = mockCoordinatorStack.sfuStack.webSocket
        XCTAssertEqual(
            webSocket
                .mockEngine
                .recordedInputPayload(
                    Stream_Video_Sfu_Event_SfuRequest.self,
                    for: .sendMessage
                )?.first?.leaveCallRequest.sessionID, sessionId
        )
        XCTAssertEqual(webSocket.timesCalled(.disconnectAsync), 1)
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
}
