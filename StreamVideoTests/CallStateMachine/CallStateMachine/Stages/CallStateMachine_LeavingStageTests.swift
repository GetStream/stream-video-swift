//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class CallStateMachineStageLeavingStage_Tests:
    StreamVideoTestCase,
    @unchecked Sendable {

    private lazy var callController: MockCallController! = .init()
    private lazy var call: MockCall! = .init(.dummy(callController: callController))
    private lazy var subject: Call.StateMachine.Stage! = .leaving(
        .init(
            call: call,
            input: .leaving(
                .init(
                    reason: nil,
                    disposableBag: DisposableBag(),
                    callController: callController,
                    closedCaptionsAdapter: ClosedCaptionsAdapter(call),
                    callCache: InjectedValues[\.callCache],
                    resetOutgoingRingingController: {},
                    resetAudioFilter: {}
                )
            )
        ),
        reason: nil
    )
    private var transitionedToStage: Call.StateMachine.Stage?

    override func tearDown() async throws {
        callController = nil
        call = nil
        subject = nil
        transitionedToStage = nil
        try await super.tearDown()
    }

    func test_transition_fromAccepting_clearsPreviousActiveCall() async {
        let previousActiveCall = MockCall(.dummy(callId: "previous-active-call"))
        streamVideo.state.activeCall = previousActiveCall
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .init(id: .accepting, context: .init(call: call)))

        await fulfilmentInMainActor {
            self.transitionedToStage?.id == .idle
                && self.streamVideo.state.activeCall == nil
        }

        XCTAssertEqual(previousActiveCall.timesCalled(.leave), 1)
    }

    func test_transition_fromJoined_keepsUnrelatedActiveCall() async {
        let previousActiveCall = MockCall(.dummy(callId: "previous-active-call"))
        streamVideo.state.activeCall = previousActiveCall
        subject.transition = { self.transitionedToStage = $0 }

        _ = subject.transition(from: .init(id: .joined, context: .init(call: call)))

        await fulfilmentInMainActor {
            self.transitionedToStage?.id == .idle
        }

        XCTAssertTrue(streamVideo.state.activeCall === previousActiveCall)
        XCTAssertEqual(previousActiveCall.timesCalled(.leave), 0)
    }
}
