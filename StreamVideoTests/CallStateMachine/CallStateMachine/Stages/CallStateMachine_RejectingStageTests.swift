//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Dispatch
@testable import StreamVideo
@preconcurrency import XCTest

final class CallStateMachineStageRejectingStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var mockDefaultAPI: MockDefaultAPI! = .init()
    private lazy var deliverySubject: CurrentValueSubject<RejectCallResponse?, Error>! = .init(nil)
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .idle, .joined
    ]
    private lazy var response: RejectCallResponse! = .init(duration: "10")

    private var transitionedToStage: Call.StateMachine.Stage?

    override func tearDown() async throws {
        validOtherStages = nil
        try await super.tearDown()
    }

    // MARK: - Test Initialization

    func test_initialization() async {
        let (call, subject) = await prepare()

        XCTAssertEqual(subject.id, .rejecting)
        XCTAssertTrue(subject.context.call === call)
    }

    // MARK: - Test Transition

    func test_transition() async {
        let (call, subject) = await prepare()
        let allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
            .allCases
            .filter { $0 != subject.id }
            .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }

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

    func test_execute_rejectCallSucceeds_deliverySubjectDeliversResponse() async throws {
        let (call, subject) = await prepare()
        mockDefaultAPI.stub(for: .rejectCall, with: response)
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { _ in XCTFail() } receiveValue: {
                XCTAssertEqual($0, self.response)
                deliveryExpectation.fulfill()
            }

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .rejected }
        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }

    func test_execute_rejectCallFails_deliverySubjectDeliversError() async {
        let (call, subject) = await prepare()
        let deliveryExpectation = expectation(description: "DeliverySubject delivered value.")
        let cancellable = deliverySubject
            .compactMap { $0 }
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

        _ = subject.transition(from: .idle(.init(call: call)))

        await safeFulfillment(of: [deliveryExpectation], timeout: defaultTimeout)
        cancellable.cancel()
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }

    func test_execute_rejectCallFails_transitionsToError() async {
        let (call, subject) = await prepare()
        mockDefaultAPI.stub(for: .rejectCall, with: ClientError())

        _ = subject.transition(from: .idle(.init(call: call)))

        await fulfilmentInMainActor { self.transitionedToStage?.id == .error }
        XCTAssertEqual(mockDefaultAPI.timesCalled(.rejectCall), 1)
    }

    // MARK: - Private Helpers

    @MainActor
    private func prepare() -> (MockCall, Call.StateMachine.Stage) {
        let call = MockCall(.dummy(coordinatorClient: mockDefaultAPI))
        let subject: Call.StateMachine.Stage = .rejecting(
            call,
            input: .rejecting(.init(deliverySubject: deliverySubject))
        )
        subject.transition = { [weak self] in self?.transitionedToStage = $0 }
        return (call, subject)
    }
}
