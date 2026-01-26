//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Dispatch
@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class StreamCallStateMachineStageAcceptingStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var mockDefaultAPI: MockDefaultAPI! = .init()
    private lazy var call: MockCall! = .init(.dummy(coordinatorClient: mockDefaultAPI))
    private lazy var deliverySubject: PassthroughSubject<AcceptCallResponse, Error>! = .init()
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .idle
    ]
    private lazy var subject: Call.StateMachine.Stage! = .accepting(
        call,
        input: .accepting(deliverySubject: deliverySubject)
    )
    private var transitionedToStage: Call.StateMachine.Stage?

    override func tearDown() async throws {
        mockDefaultAPI = nil
        call = nil
        deliverySubject = nil
        allOtherStages = nil
        validOtherStages = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Test Initialization

    func test_initialization() {
        XCTAssertEqual(subject.id, .accepting)
        XCTAssertTrue(subject.context.call === call)
    }

    // MARK: - Test Transition

    func test_transition() async {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                mockDefaultAPI.stub(for: .acceptCall, with: AcceptCallResponse(duration: "10"))
                subject.transition = { self.transitionedToStage = $0 }
                XCTAssertNotNil(subject.transition(from: nextStage))
                await fulfilmentInMainActor(timeout: defaultTimeout) { self.transitionedToStage != nil }
                XCTAssertEqual(transitionedToStage?.id, .accepted)
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }

    func test_execute_acceptCallSucceeds_deliverySubjectDeliversResponse() async {
        let expected = AcceptCallResponse(duration: "10")
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .receive(on: DispatchQueue.main)
            .sink { _ in XCTFail() } receiveValue: {
                XCTAssertEqual($0, expected)
                deliveryExpectation.fulfill()
            }
        mockDefaultAPI.stub(for: .acceptCall, with: expected)
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .accepted }
        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.acceptCall), 1)
    }

    func test_execute_acceptCallFails_deliverySubjectDeliversError() async {
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
        mockDefaultAPI.stub(for: .acceptCall, with: ClientError())
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.acceptCall), 1)
    }

    func test_execute_acceptCallFails_transitionsToError() async {
        mockDefaultAPI.stub(for: .acceptCall, with: ClientError())
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .error }
        XCTAssertEqual(mockDefaultAPI.timesCalled(.acceptCall), 1)
    }
}

extension Call.StateMachine.Stage.Context.Input {
    var accepting: PassthroughSubject<AcceptCallResponse, Error>? {
        switch self {
        case let .accepting(deliverySubject):
            return deliverySubject
        default:
            return nil
        }
    }
}
