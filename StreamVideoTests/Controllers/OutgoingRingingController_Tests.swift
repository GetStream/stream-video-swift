//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class OutgoingRingingController_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var applicationStateAdapter: MockAppStateAdapter! = .init()
    private lazy var callType: String! = .default
    private lazy var callId: String! = .unique
    private lazy var otherCallId: String! = .unique
    private var subject: OutgoingRingingController!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        applicationStateAdapter.makeShared()
    }

    override func tearDown() {
        applicationStateAdapter.dismante()

        subject = nil
        otherCallId = nil
        callId = nil
        callType = nil
        applicationStateAdapter = nil
        super.tearDown()
    }

    // MARK: - init

    func test_matchingRingingCall_onBackground_handlerIsCalled() async {
        let call = streamVideo.call(callType: callType, callId: callId)
        let handlerWasCalled = expectation(description: "Handler was called.")
        subject = makeSubject(for: call) {
            handlerWasCalled.fulfill()
        }

        streamVideo.state.ringingCall = call
        applicationStateAdapter.stubbedState = .background

        await fulfillment(of: [handlerWasCalled])
    }

    func test_nonMatchingRingingCall_onBackground_handlerIsNotCalled() async {
        let call = streamVideo.call(callType: callType, callId: callId)
        let otherCall = streamVideo.call(callType: callType, callId: otherCallId)
        let handlerWasCalled = expectation(description: "Handler was called.")
        handlerWasCalled.isInverted = true
        subject = makeSubject(for: call) {
            handlerWasCalled.fulfill()
        }

        streamVideo.state.ringingCall = otherCall
        applicationStateAdapter.stubbedState = .background

        await fulfillment(of: [handlerWasCalled], timeout: 0.2)
    }

    // MARK: - Private Helpers

    private func makeSubject(
        for call: Call,
        handler: @escaping () async throws -> Void
    ) -> OutgoingRingingController {
        .init(
            streamVideo: streamVideo,
            callCiD: call.cId,
            handler: handler
        )
    }
}
