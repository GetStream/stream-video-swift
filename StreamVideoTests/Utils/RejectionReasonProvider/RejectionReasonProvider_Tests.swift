//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamRejectionReasonProviderTests: XCTestCase {

    private lazy var mockStreamVideo: MockStreamVideo! = MockStreamVideo()
    private lazy var subject: StreamRejectionReasonProvider! = {
        let subject = StreamRejectionReasonProvider()
        subject.streamVideo = mockStreamVideo
        return subject
    }()

    override func tearDown() {
        subject = nil
        mockStreamVideo = nil
        super.tearDown()
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndRingTimeout_whenUserIsBusy_thenReturnsBusyReason() {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.activeCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall

        let reason = subject.rejectionReason(
            for: ringingCall.cId,
            ringTimeout: true
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.busy)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndRingTimeout_whenUserIsRejectingOutgoingCall_thenReturnsTimeoutReason(
    ) {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = mockStreamVideo.user

        let reason = subject.rejectionReason(
            for: ringingCall.cId,
            ringTimeout: true
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.timeout)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndNoRingTimeout_whenUserIsRejectingOutgoingCall_thenReturnsCancelReason(
    ) {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = mockStreamVideo.user

        let reason = subject.rejectionReason(
            for: ringingCall.cId,
            ringTimeout: false
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.cancel)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndNoRingTimeout_whenUserIsNotBusyAndNotRejectingOutgoingCall_thenReturnsDeclineReason(
    ) {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = .dummy()

        let reason = subject.rejectionReason(
            for: ringingCall.cId,
            ringTimeout: false
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.decline)
    }

    @MainActor
    func test_rejectionReason_givenNoRingingCallMatchingCid_thenReturnsNil() {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = .dummy()

        let reason = subject.rejectionReason(
            for: .unique,
            ringTimeout: false
        )

        XCTAssertNil(reason)
    }

    @MainActor
    func test_rejectionReason_givenNoRingingCall_thenReturnsNil() {
        let reason = subject.rejectionReason(
            for: .unique,
            ringTimeout: false
        )

        XCTAssertNil(reason)
    }
}
