//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_ConnectingStageTests: XCTestCase, @unchecked Sendable {

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.idle, .rejoining]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .connecting(.init(), ring: true)
    private lazy var mockCoordinatorStack: MockWebRTCCoordinatorStack! = .init()

    override func tearDown() {
        allOtherStages = nil
        validStages = nil
        subject = nil
        mockCoordinatorStack = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init() {
        XCTAssertEqual(subject.id, .connecting)
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

    // MARK: - transition from `.idle`

    func test_transition_fromIdleWithoutCoordinator_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .idle,
            expectedTarget: .disconnected,
            subject: .connecting(.init(), ring: true)
        ) { target in
            XCTAssertNotNil(target.context.flowError as? ClientError)
        }
    }

    func test_transition_fromIdle_doesNotUpdateSession() async throws {
        let expectedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID

        try await assertTransition(
            from: .idle,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] _ in
            let actual = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            XCTAssertEqual(actual, expectedSessionId)
        }
    }

    func test_transition_fromIdleRingTrueAuthenticationFails_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .idle,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] target in
            let callType = (
                coordinator: WebRTCCoordinator,
                currentSFU: String?,
                create: Bool,
                ring: Bool
            ).self
            let input = try XCTUnwrap(
                mockCoordinatorStack?.webRTCAuthenticator.recordedInputPayload(
                    callType,
                    for: .authenticate
                )?.first
            )
            XCTAssertTrue(input.coordinator === mockCoordinatorStack?.coordinator)
            XCTAssertNil(input.currentSFU)
            XCTAssertTrue(input.create)
            XCTAssertTrue(input.ring)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromIdleRingFalseAuthenticationFails_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .idle,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: false
            )
        ) { [mockCoordinatorStack] target in
            let callType = (
                coordinator: WebRTCCoordinator,
                currentSFU: String?,
                create: Bool,
                ring: Bool
            ).self
            let input = try XCTUnwrap(
                mockCoordinatorStack?.webRTCAuthenticator.recordedInputPayload(
                    callType,
                    for: .authenticate
                )?.first
            )
            XCTAssertTrue(input.coordinator === mockCoordinatorStack?.coordinator)
            XCTAssertNil(input.currentSFU)
            XCTAssertTrue(input.create)
            XCTAssertFalse(input.ring)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromIdleSFUConnectFails_transitionsToDisconnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )

        try await assertTransition(
            from: .idle,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] target in
            let input = try XCTUnwrap(
                mockCoordinatorStack?
                    .webRTCAuthenticator
                    .recordedInputPayload(SFUAdapter.self, for: .waitForAuthentication)?
                    .first
            )
            XCTAssertTrue(input === mockCoordinatorStack?.sfuStack.adapter)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromIdleSFUConnectedAndStateAdapterUpdated_transitionsToConnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )

        try await assertTransition(
            from: .idle,
            expectedTarget: .connected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] _ in
            let stateAdapter = try XCTUnwrap(mockCoordinatorStack?.coordinator.stateAdapter)
            let sfuAdapter = await stateAdapter.sfuAdapter
            XCTAssertTrue(sfuAdapter === mockCoordinatorStack?.sfuStack.adapter)
        }
    }

    func test_transition_fromIdleSFUConnectedContextWasUpdated_transitionsToConnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<
                (SFUAdapter, JoinCallResponse),
                Error
            >
            .success(
                (
                    mockCoordinatorStack.sfuStack.adapter,
                    .dummy(credentials: .dummy(server: .dummy(edgeName: "test-sfu")))
                )
            )
        )
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )

        try await assertTransition(
            from: .idle,
            expectedTarget: .connected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { target in
            XCTAssertEqual(target.context.currentSFU, "test-sfu")
        }
    }

    // MARK: - transition from `.rejoining`

    func test_transition_fromRejoiningWithoutCoordinator_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .rejoining,
            expectedTarget: .disconnected,
            subject: .connecting(.init(), ring: true)
        ) { target in
            XCTAssertNotNil(target.context.flowError as? ClientError)
        }
    }

    func test_transition_fromRejoining_updatesSession() async throws {
        let expectedSessionId = await mockCoordinatorStack
            .coordinator
            .stateAdapter
            .sessionID

        try await assertTransition(
            from: .rejoining,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] _ in
            let actual = await mockCoordinatorStack?.coordinator.stateAdapter.sessionID
            XCTAssertNotEqual(actual, expectedSessionId)
        }
    }

    func test_transition_fromRejoiningRingTrueAuthenticationFails_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .rejoining,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] target in
            let callType = (
                coordinator: WebRTCCoordinator,
                currentSFU: String?,
                create: Bool,
                ring: Bool
            ).self
            let input = try XCTUnwrap(
                mockCoordinatorStack?.webRTCAuthenticator.recordedInputPayload(
                    callType,
                    for: .authenticate
                )?.first
            )
            XCTAssertTrue(input.coordinator === mockCoordinatorStack?.coordinator)
            XCTAssertNil(input.currentSFU)
            XCTAssertFalse(input.create)
            XCTAssertTrue(input.ring)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromRejoiningRingFalseAuthenticationFails_transitionsToDisconnected() async throws {
        try await assertTransition(
            from: .rejoining,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: false
            )
        ) { [mockCoordinatorStack] target in
            let callType = (
                coordinator: WebRTCCoordinator,
                currentSFU: String?,
                create: Bool,
                ring: Bool
            ).self
            let input = try XCTUnwrap(
                mockCoordinatorStack?.webRTCAuthenticator.recordedInputPayload(
                    callType,
                    for: .authenticate
                )?.first
            )
            XCTAssertTrue(input.coordinator === mockCoordinatorStack?.coordinator)
            XCTAssertNil(input.currentSFU)
            XCTAssertFalse(input.create)
            XCTAssertFalse(input.ring)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromRejoiningSFUConnectFails_transitionsToDisconnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )

        try await assertTransition(
            from: .rejoining,
            expectedTarget: .disconnected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [error, mockCoordinatorStack] target in
            let input = try XCTUnwrap(
                mockCoordinatorStack?
                    .webRTCAuthenticator
                    .recordedInputPayload(SFUAdapter.self, for: .waitForAuthentication)?
                    .first
            )
            XCTAssertTrue(input === mockCoordinatorStack?.sfuStack.adapter)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromRejoiningSFUConnectedAndStateAdapterUpdated_transitionsToConnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )

        try await assertTransition(
            from: .rejoining,
            expectedTarget: .connected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { [mockCoordinatorStack] _ in
            let stateAdapter = try XCTUnwrap(mockCoordinatorStack?.coordinator.stateAdapter)
            let sfuAdapter = await stateAdapter.sfuAdapter
            XCTAssertTrue(sfuAdapter === mockCoordinatorStack?.sfuStack.adapter)
        }
    }

    func test_transition_fromRejoiningSFUConnectedContextWasUpdated_transitionsToConnected() async throws {
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<
                (SFUAdapter, JoinCallResponse),
                Error
            >
            .success(
                (
                    mockCoordinatorStack.sfuStack.adapter,
                    .dummy(credentials: .dummy(server: .dummy(edgeName: "test-sfu")))
                )
            )
        )
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )

        try await assertTransition(
            from: .rejoining,
            expectedTarget: .connected,
            subject: .connecting(
                .init(
                    coordinator: mockCoordinatorStack.coordinator,
                    authenticator: mockCoordinatorStack.webRTCAuthenticator
                ),
                ring: true
            )
        ) { target in
            XCTAssertEqual(target.context.currentSFU, "test-sfu")
        }
    }

    // MARK: - Private helpers

    private func assertTransition(
        from: WebRTCCoordinator.StateMachine.Stage.ID,
        expectedTarget: WebRTCCoordinator.StateMachine.Stage.ID,
        subject: WebRTCCoordinator.StateMachine.Stage,
        validator: @escaping (WebRTCCoordinator.StateMachine.Stage) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let transitionExpectation =
            expectation(description: "Stage id:\(subject.id) is expected to transition to id:\(expectedTarget).")
        subject.transition = { [validator] target in
            guard target.id == expectedTarget else {
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
