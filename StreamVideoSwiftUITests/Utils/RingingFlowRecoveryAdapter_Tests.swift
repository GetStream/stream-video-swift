//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class RingingFlowRecoveryAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var streamVideo: MockStreamVideo! = .init()
    private var call: Call!
    private var accepted: [StreamVideoSwiftUI.CallEvent] = []
    private var rejected: [StreamVideoSwiftUI.CallEvent] = []
    private var ended: [StreamVideoSwiftUI.CallEvent] = []
    private var subject: RingingFlowRecoveryAdapter!

    override func setUp() async throws {
        try await super.setUp()
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

    private func attachOutgoingRing() async {
        call.state.createdBy = streamVideo.user
        streamVideo.state.ringingCall = call
        await wait(for: defaultTimeoutForInversedExpecations)
    }
}
