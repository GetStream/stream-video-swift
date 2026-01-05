//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamRejectionReasonProviderTests: XCTestCase, @unchecked Sendable {

    private lazy var mockStreamVideo: MockStreamVideo! = MockStreamVideo()
    private lazy var subject: StreamRejectionReasonProvider! = StreamRejectionReasonProvider(mockStreamVideo)

    override func tearDown() {
        subject = nil
        mockStreamVideo = nil
        super.tearDown()
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndRingTimeout_whenUserIsBusy_thenReturnsBusyReason() async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.activeCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall

        let reason = await subject.reason(
            for: ringingCall.cId,
            ringTimeout: true
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.busy)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndRingTimeout_whenUserIsRejectingOutgoingCall_thenReturnsCancelReason(
    ) async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = mockStreamVideo.user

        let reason = await subject.reason(
            for: ringingCall.cId,
            ringTimeout: true
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.cancel)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndNoRingTimeout_whenUserIsRejectingOutgoingCall_thenReturnsCancelReason(
    ) async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = mockStreamVideo.user

        let reason = await subject.reason(
            for: ringingCall.cId,
            ringTimeout: false
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.cancel)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndNoRingTimeout_whenUserIsNotBusyAndNotRejectingOutgoingCall_thenReturnsDeclineReason(
    ) async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = .dummy()

        let reason = await subject.reason(
            for: ringingCall.cId,
            ringTimeout: false
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.decline)
    }

    @MainActor
    func test_rejectionReason_givenRingingCallWithMatchingCidAndRingTimeout_whenUserIsNotBusyAndNotRejectingOutgoingCall_thenReturnsTimeoutReason(
    ) async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = .dummy()

        let reason = await subject.reason(
            for: ringingCall.cId,
            ringTimeout: true
        )

        XCTAssertEqual(reason, RejectCallRequest.Reason.timeout)
    }

    @MainActor
    func test_rejectionReason_givenNoRingingCallMatchingCid_thenReturnsNil() async {
        let ringingCall = MockCall(.dummy())
        mockStreamVideo.state.ringingCall = ringingCall
        ringingCall.state.createdBy = .dummy()

        let reason = await subject.reason(
            for: .unique,
            ringTimeout: false
        )

        XCTAssertNil(reason)
    }

    @MainActor
    func test_rejectionReason_givenNoRingingCall_thenReturnsNil() async {
        let reason = await subject.reason(
            for: .unique,
            ringTimeout: false
        )

        XCTAssertNil(reason)
    }
}
