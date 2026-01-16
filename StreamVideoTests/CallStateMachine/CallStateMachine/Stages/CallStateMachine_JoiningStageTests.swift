//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Dispatch
@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class StreamCallStateMachineStageJoiningStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var callController: MockCallController! = .init()
    private lazy var call: MockCall! = .init(.dummy(callController: callController))
    private lazy var input: Call.StateMachine.Stage.Context.Input! = .join(
        .init(
            create: true,
            ring: true,
            notify: true,
            source: .inApp,
            deliverySubject: .init(nil)
        )
    )
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .idle, .accepted, .joining
    ]
    private lazy var subject: Call.StateMachine.Stage! = .joining(call, input: input)
    private var transitionedToStage: Call.StateMachine.Stage?

    // MARK: - Lifecycle

    override func tearDown() async throws {
        call = nil
        callController = nil
        input = nil
        allOtherStages = nil
        validOtherStages = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Test Initialization

    func test_initialization() {
        XCTAssertEqual(subject.id, .joining)
        XCTAssertTrue(subject.context.call === call)
    }

    // MARK: - Test Transition

    @MainActor
    func test_transition() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                subject.transition = { self.transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfilmentInMainActor(timeout: defaultTimeout) { self.transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .joining)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }

    // MARK: - execute

    func test_execute_callIsNil_transitionsToError() async {
        subject.transition = { self.transitionedToStage = $0 }
        subject.context.call = nil

        _ = subject.transition(from: .idle(.init()))

        await fulfilmentInMainActor(timeout: defaultTimeout) { self.transitionedToStage != nil }

        XCTAssertEqual(transitionedToStage?.id, .error)
    }

    func test_execute_inputIsNil_transitionsToError() async {
        subject.transition = { self.transitionedToStage = $0 }
        subject.context.call = call
        subject.context.input = .none

        _ = subject.transition(from: .idle(.init()))

        await fulfilmentInMainActor(timeout: defaultTimeout) { self.transitionedToStage != nil }

        XCTAssertEqual(transitionedToStage?.id, .error)
    }

    func test_execute_withoutRetries_joinCallWasCalledOnCallControllerWithExpectedInput() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil),
                    retryPolicy: .init(maxRetries: 0, delay: { _ in 0 })
                )
            )
        )

        try await assertJoining(context, expectedTransition: .error) {
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            try self.validateCallControllerJoinCall(context: context)
        }
    }

    func test_execute_withoutRetries_callStateCallSettingsUpdatedWithInput() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil)
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: JoinCallResponse.dummy(),
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            await self.fulfilmentInMainActor { self.call!.state.callSettings == context.input.join?.callSettings }
        }
    }

    @MainActor
    func test_execute_withoutRetries_callStateUpdatedWithInput() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil)
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: JoinCallResponse.dummy(ownCapabilities: [.changeMaxDuration]),
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            XCTAssertEqual(self.call.state.ownCapabilities, [.changeMaxDuration])
        }
    }

    func test_execute_withoutRetries_updatesCallSettingsManagers() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil)
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: JoinCallResponse.dummy(ownCapabilities: [.changeMaxDuration]),
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            XCTAssertEqual(self.call.microphone.status, .disabled)
        }
    }

    func test_execute_withoutRetries_updatesStreamVideoActiveCall() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil)
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: JoinCallResponse.dummy(ownCapabilities: [.changeMaxDuration]),
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            XCTAssertEqual(self.streamVideo.state.activeCall?.cId, self.call.cId)
        }
    }

    func test_execute_withoutRetries_deliverySubjectsReceivesTheJoinCallResponse() async throws {
        let deliverySubject = CurrentValueSubject<JoinCallResponse?, Error>(nil)
        let joinCallResponse = JoinCallResponse.dummy(ownCapabilities: [.changeMaxDuration])
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { _ in XCTFail() } receiveValue: {
                XCTAssertEqual($0, joinCallResponse)
                deliveryExpectation.fulfill()
            }

        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: deliverySubject
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: joinCallResponse,
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            XCTAssertEqual(self.streamVideo.state.activeCall?.cId, self.call.cId)
        }

        await fulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
    }

    func test_execute_withoutRetries_beginsObservingWebRTCStateOnCallController() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil)
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: JoinCallResponse.dummy(ownCapabilities: [.changeMaxDuration]),
            expectedTransition: .joined
        ) { @MainActor in
            XCTAssertEqual(self.callController.timesCalled(.join), 1)
            XCTAssertEqual(self.callController.timesCalled(.observeWebRTCStateUpdated), 1)
        }
    }

    func test_execute_withRetries_whenJoinFailsAndThereAreAvailableRetries_transitionsToJoining() async throws {
        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: .init(nil),
                    retryPolicy: .init(maxRetries: 2, delay: { _ in 0 })
                )
            )
        )

        try await assertJoining(
            context,
            expectedTransition: .error
        ) {
            await self.fulfilmentInMainActor { self.callController.timesCalled(.join) == 2 }
        }
    }

    func test_execute_withRetries_whenJoinFailsAndThereAreAvailableRetries_afterRetriesFailItDeliversErrorToDeliverySubject(
    ) async throws {
        let deliverySubject = CurrentValueSubject<JoinCallResponse?, Error>(nil)
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink {
                switch $0 {
                case .finished:
                    XCTFail()
                case let .failure(error):
                    XCTAssertTrue(error is ClientError)
                    deliveryExpectation.fulfill()
                }
            } receiveValue: { _ in XCTFail() }

        let context = Call.StateMachine.Stage.Context(
            call: call,
            input: .join(
                .init(
                    create: true,
                    callSettings: .init(audioOn: false),
                    options: .init(memberIds: [.unique]),
                    ring: true,
                    notify: false,
                    source: .inApp,
                    deliverySubject: deliverySubject,
                    retryPolicy: .init(maxRetries: 2, delay: { _ in 0 })
                )
            )
        )

        try await assertJoining(
            context,
            joinResponse: ClientError(),
            expectedTransition: .error
        ) {}

        await fulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
    }

    // MARK: - Private helpers

    private func assertJoining(
        _ context: Call.StateMachine.Stage.Context,
        transitionFrom: Call.StateMachine.Stage.ID = .idle,
        joinResponse: Any = ClientError(),
        expectedTransition: Call.StateMachine.Stage.ID,
        validationHandler: @escaping () async throws -> Void = {},
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        callController.stub(for: .join, with: joinResponse)
        subject.transition = {
            self.transitionedToStage = $0
            if
                $0.id == .joining,
                case let .join(joinInput) = $0.context.input,
                joinInput.currentNumberOfRetries < joinInput.retryPolicy.maxRetries {
                $0.transition = self.subject.transition
                _ = $0.transition(from: self.subject)
            }
        }
        subject.context = context

        _ = subject.transition(from: .init(id: transitionFrom, context: .init()))

        await fulfilmentInMainActor(
            file: file,
            line: line
        ) { self.transitionedToStage?.id == expectedTransition }

        try await validationHandler()
    }

    private func validateCallControllerJoinCall(
        iteration: Int = 0,
        context: Call.StateMachine.Stage.Context
    ) throws {
        let joinInputType = (Bool, CallSettings?, CreateCallOptions?, Bool, Bool, JoinSource).self
        let recordedInput = try XCTUnwrap(
            callController.recordedInputPayload(
                joinInputType,
                for: .join
            )?[iteration]
        )
        XCTAssertEqual(context.input.join?.create, recordedInput.0)
        XCTAssertEqual(context.input.join?.callSettings, recordedInput.1)
        XCTAssertEqual(context.input.join?.options, recordedInput.2)
        XCTAssertEqual(context.input.join?.ring, recordedInput.3)
        XCTAssertEqual(context.input.join?.notify, recordedInput.4)
    }
}

extension Call.StateMachine.Stage.Context.Input {
    var join: Call.StateMachine.Stage.Context.JoinInput? {
        switch self {
        case let .join(input):
            return input
        default:
            return nil
        }
    }
}
