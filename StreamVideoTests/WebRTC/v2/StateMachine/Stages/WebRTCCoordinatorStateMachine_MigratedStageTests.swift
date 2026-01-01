//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCCoordinatorStateMachine_MigratedStageTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private lazy var allOtherStages: [WebRTCCoordinator.StateMachine.Stage]! = WebRTCCoordinator
        .StateMachine
        .Stage
        .ID
        .allCases
        .filter { $0 != subject.id }
        .map { WebRTCCoordinator.StateMachine.Stage(id: $0, context: .init()) }
    private lazy var validStages: Set<WebRTCCoordinator.StateMachine.Stage.ID>! = [.migrating]
    private lazy var subject: WebRTCCoordinator.StateMachine.Stage! = .migrated(.init())
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
        XCTAssertEqual(subject.id, .migrated)
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
            from: .migrating,
            expectedTarget: .disconnected,
            subject: subject
        ) { target in
            XCTAssertNotNil(target.context.flowError as? ClientError)
        }
    }

    func test_transition_authenticationFails_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        let migratingFromSFU = String.unique
        subject.context.migratingFromSFU = migratingFromSFU

        try await assertTransition(
            from: .migrating,
            expectedTarget: .disconnected,
            subject: subject
        ) { [mockCoordinatorStack] target in
            let callType = (
                coordinator: WebRTCCoordinator,
                currentSFU: String?,
                create: Bool,
                ring: Bool,
                notify: Bool,
                options: CreateCallOptions?
            ).self
            let input = try XCTUnwrap(
                mockCoordinatorStack?.webRTCAuthenticator.recordedInputPayload(
                    callType,
                    for: .authenticate
                )?.first
            )
            XCTAssertTrue(input.coordinator === mockCoordinatorStack?.coordinator)
            XCTAssertEqual(input.currentSFU, migratingFromSFU)
            XCTAssertFalse(input.create)
            XCTAssertFalse(input.ring)
            XCTAssertFalse(input.notify)
            XCTAssertNil(input.options)
            XCTAssertTrue(target.context.flowError is ClientError)
        }
    }

    func test_transition_fromIdleSFUConnectFails_transitionsToDisconnected() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        subject.context.currentSFU = .unique
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )

        try await assertTransition(
            from: .migrating,
            expectedTarget: .disconnected,
            subject: subject
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

    func test_transition_SFUConnectedAndStateAdapterUpdated() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        subject.context.currentSFU = .unique
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
            from: .migrating,
            expectedTarget: .joining,
            subject: subject
        ) { [mockCoordinatorStack] _ in
            let stateAdapter = try XCTUnwrap(mockCoordinatorStack?.coordinator.stateAdapter)
            let sfuAdapter = await stateAdapter.sfuAdapter
            XCTAssertTrue(sfuAdapter === mockCoordinatorStack?.sfuStack.adapter)
        }
    }

    func test_transition_currentSFUInContextWasUpdated() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        subject.context.currentSFU = .unique
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
            from: .migrating,
            expectedTarget: .joining,
            subject: subject
        ) { target in
            XCTAssertEqual(target.context.currentSFU, "test-sfu")
        }
    }

    func test_transition_previousSFUAdapterIsAvailable_migrationStatusObserverWasCreatedInContext() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        subject.context.currentSFU = .unique
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .authenticate,
            with: Result<(SFUAdapter, JoinCallResponse), Error>
                .success((mockCoordinatorStack.sfuStack.adapter, .dummy()))
        )
        mockCoordinatorStack.webRTCAuthenticator.stub(
            for: .waitForAuthentication,
            with: Result<Void, Error>.success(())
        )
        let previousSFUAdapterStack = MockSFUStack()
        subject.context.previousSFUAdapter = previousSFUAdapterStack.adapter

        try await assertTransition(
            from: .migrating,
            expectedTarget: .joining,
            subject: subject
        ) { target in
            XCTAssertNotNil(target.context.migrationStatusObserver)
        }
    }

    func test_transition_previousSFUAdapterIsNotAvailable_migrationStatusObserverIsNilInContext() async throws {
        subject.context.coordinator = mockCoordinatorStack.coordinator
        subject.context.authenticator = mockCoordinatorStack.webRTCAuthenticator
        subject.context.currentSFU = .unique
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
            from: .migrating,
            expectedTarget: .joining,
            subject: subject
        ) { target in
            XCTAssertNil(target.context.migrationStatusObserver)
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
