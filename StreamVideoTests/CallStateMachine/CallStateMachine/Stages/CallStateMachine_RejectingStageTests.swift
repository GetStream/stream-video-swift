//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Dispatch
@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class CallStateMachineStageRejectingStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var mockDefaultAPI: MockDefaultAPI! = .init()
    private lazy var call: MockCall! = .init(.dummy(coordinatorClient: mockDefaultAPI))
    private lazy var deliverySubject: PassthroughSubject<RejectCallResponse, Error>! = .init()
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .idle, .joined
    ]
    private lazy var response: RejectCallResponse! = .init(duration: "10")
    private lazy var subject: Call.StateMachine.Stage! = .rejecting(
        call,
        input: .rejecting(.init(deliverySubject: deliverySubject))
    )

    private var transitionedToStage: Call.StateMachine.Stage?

    override func tearDown() async throws {
        call = nil
        allOtherStages = nil
        validOtherStages = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Test Initialization

    func test_initialization() {
        XCTAssertEqual(subject.id, .rejecting)
        XCTAssertTrue(subject.context.call === call)
    }

    // MARK: - Test Transition

    func test_transition() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                mockDefaultAPI.stub(for: .rejectCall, with: response)
                subject.transition = { self.transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfilmentInMainActor(timeout: defaultTimeout) { self.transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .rejected)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }

    func test_execute_rejectCallSucceeds_deliverySubjectDeliversResponse() async {
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .receive(on: DispatchQueue.main)
            .sink { _ in XCTFail() } receiveValue: {
                XCTAssertEqual($0, self.response)
                deliveryExpectation.fulfill()
            }
        mockDefaultAPI.stub(for: .rejectCall, with: response)
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .rejected }
        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }

    func test_execute_rejectCallFails_deliverySubjectDeliversError() async {
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .receive(on: DispatchQueue.main)
            .sink {
                switch $0 {
                case .finished:
                    XCTFail()
                case let .failure(error):
                    XCTAssertTrue(error is ClientError)
                    deliveryExpectation.fulfill()
                }
            } receiveValue: { _ in XCTFail() }
        mockDefaultAPI.stub(for: .rejectCall, with: ClientError())
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }

    func test_execute_rejectCallFails_transitionsToError() async {
        mockDefaultAPI.stub(for: .rejectCall, with: ClientError())
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .error }
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }
}
