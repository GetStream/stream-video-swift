//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class RingingFlowRecoveryAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var streamVideo: MockStreamVideo!
    private var call: Call!
    private var accepted: [StreamVideoSwiftUI.CallEvent] = []
    private var rejected: [StreamVideoSwiftUI.CallEvent] = []
    private var ended: [StreamVideoSwiftUI.CallEvent] = []
    private var subject: RingingFlowRecoveryAdapter!

    override func setUp() async throws {
        try await super.setUp()
        streamVideo = .init()
        call = .dummy()
        subject = .init(
            streamVideo,
            onAccepted: { [weak self] in self?.accepted.append($0) },
            onRejected: { [weak self] in self?.rejected.append($0) },
            onEnded: { [weak self] in self?.ended.append($0) }
        )
    }

    override func tearDown() async throws {
        subject = nil
        call = nil
        streamVideo = nil
        accepted = []
        rejected = []
        ended = []
        try await super.tearDown()
    }

    // MARK: - outgoing ring

    func test_outgoingRing_sessionAcceptedByOtherUser_onAccepted() async {
        await attachOutgoingRing()

        call.state.session = .dummy(
            acceptedBy: [User.dummy().id: Date()]
        )

        await fulfilmentInMainActor { self.accepted.count == 1 }
        XCTAssertTrue(rejected.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_outgoingRing_sessionRejectedByOtherUser_onRejected() async {
        await attachOutgoingRing()

        call.state.session = .dummy(
            rejectedBy: [User.dummy().id: Date()]
        )

        await fulfilmentInMainActor { self.rejected.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_outgoingRing_sessionEndedAtWithMissedBy_onEnded() async {
        await attachOutgoingRing()

        call.state.session = .dummy(
            endedAt: Date(),
            missedBy: [User.dummy().id: Date()]
        )

        await fulfilmentInMainActor { self.ended.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    func test_outgoingRing_endedWithHistoricalAcceptance_onlyEnds() async {
        await attachOutgoingRing()
        call.state.session = .dummy(
            acceptedBy: ["previous-callee": Date()],
            endedAt: Date(),
            id: "ring-session"
        )

        await fulfilmentInMainActor { self.ended.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    func test_outgoingRing_nonmemberAndInviteeAccepted_emitsBothOutcomes() async {
        await attachOutgoingRing()
        call.state.session = .dummy(
            acceptedBy: ["previous-callee": Date(), "invited-callee": Date()],
            id: "ring-session"
        )

        await fulfilmentInMainActor { self.accepted.count == 2 }
        let userIds = Set(accepted.compactMap { event -> String? in
            if case let .accepted(info) = event { return info.user?.id }
            return nil
        })
        XCTAssertEqual(userIds, ["previous-callee", "invited-callee"])
    }

    func test_outgoingRing_emptySession_noCallbacks() async {
        await attachOutgoingRing()

        call.state.session = .dummy()

        await wait(for: defaultTimeoutForInversedExpecations)

        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    // MARK: - incoming ring

    func test_incomingRing_sessionAcceptedByOtherUser_noCallbacks() async {
        call.state.createdBy = .dummy()
        streamVideo.state.ringingCall = call
        await wait(for: defaultTimeoutForInversedExpecations)

        call.state.session = .dummy(
            acceptedBy: [User.dummy().id: Date()]
        )

        await wait(for: defaultTimeoutForInversedExpecations)

        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_incomingRing_sessionAcceptedByCurrentUser_onAccepted() async {
        await attachIncomingRing()
        call.state.session = .dummy(acceptedBy: [streamVideo.user.id: Date()])

        await fulfilmentInMainActor { self.accepted.count == 1 }
        XCTAssertTrue(rejected.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_incomingRing_sessionRejectedByCaller_onRejected() async {
        await attachIncomingRing()
        call.state.session = .dummy(rejectedBy: ["caller": Date()])

        await fulfilmentInMainActor { self.rejected.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_incomingRing_callerRejectedAfterAnotherCalleeAccepted_keepsRinging() async {
        await attachIncomingRing()
        call.state.session = .dummy(
            acceptedBy: ["other-callee": Date()],
            rejectedBy: ["caller": Date()]
        )

        await wait(for: defaultTimeoutForInversedExpecations)
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
        XCTAssertTrue(ended.isEmpty)
    }

    func test_incomingRing_sessionMissedByCurrentUser_onEnded() async {
        await attachIncomingRing()
        call.state.session = .dummy(missedBy: [streamVideo.user.id: Date()])

        await fulfilmentInMainActor { self.ended.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    func test_incomingRing_endedWithHistoricalAcceptance_onlyEnds() async {
        await attachIncomingRing()
        call.state.session = .dummy(
            acceptedBy: [streamVideo.user.id: Date()],
            endedAt: Date()
        )

        await fulfilmentInMainActor { self.ended.count == 1 }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    func test_incomingRing_endedWithoutSession_onEnded() async {
        await attachIncomingRing()
        call.state.session = nil
        call.state.endedAt = Date()

        await fulfilmentInMainActor { !self.ended.isEmpty }
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    // MARK: - createdBy hydration after ringingCall is set

    func test_ringingCallAssignedBeforeCreatedBy_laterSessionUpdate_onAccepted() async {
        streamVideo.state.ringingCall = call
        await wait(for: defaultTimeoutForInversedExpecations)
        XCTAssertNil(call.state.createdBy)

        call.state.createdBy = streamVideo.user
        call.state.session = .dummy(
            acceptedBy: [User.dummy().id: Date()]
        )

        await fulfilmentInMainActor { self.accepted.count == 1 }
    }

    // MARK: - Private Helpers

    private func attachIncomingRing() async {
        call.state.createdBy = .dummy(id: "caller")
        streamVideo.state.ringingCall = call
        await wait(for: defaultTimeoutForInversedExpecations)
    }

    private func attachOutgoingRing() async {
        call.state.createdBy = streamVideo.user
        streamVideo.state.ringingCall = call
        await wait(for: defaultTimeoutForInversedExpecations)
    }
}
