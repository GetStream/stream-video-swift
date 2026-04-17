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

    func test_handledCallReason_givenEndedCall_thenReturnsCallHasEndedReason() async {
        let callCid = "default:\(String.unique)"

        let reason = subject.reason(
            callState: .dummy(
                call: .dummy(
                    cid: callCid,
                    endedAt: .init()
                )
            )
        )

        XCTAssertEqual(
            reason,
            StreamRejectionReasonProvider.HandledCallReason.callHasEnded.rawValue
        )
    }

    func test_handledCallReason_givenCurrentUserAcceptedElsewhere_thenReturnsUserRespondedElsewhereReason() async {
        let callCid = "default:\(String.unique)"

        let reason = subject.reason(
            callState: .dummy(
                call: .dummy(
                    cid: callCid,
                    session: .dummy(
                        acceptedBy: [mockStreamVideo.user.id: Date()]
                    )
                )
            )
        )

        XCTAssertEqual(
            reason,
            StreamRejectionReasonProvider.HandledCallReason.userRespondedElsewhere.rawValue
        )
    }

    func test_handledCallReason_givenCreatorRejectedBeforeAnotherParticipantAccepted_thenReturnsCreatorRejectedReason() async {
        let callCid = "default:\(String.unique)"
        let creatorId = "creator"

        let reason = subject.reason(
            callState: .dummy(
                call: .dummy(
                    cid: callCid,
                    createdBy: .dummy(id: creatorId),
                    session: .dummy(
                        rejectedBy: [creatorId: Date()]
                    )
                ),
                members: [
                    .dummy(userId: creatorId),
                    .dummy(userId: mockStreamVideo.user.id)
                ]
            )
        )

        XCTAssertEqual(
            reason,
            StreamRejectionReasonProvider.HandledCallReason.creatorRejected.rawValue
        )
    }

    func test_handledCallReason_givenCreatorRejectedAfterAnotherParticipantAccepted_thenReturnsNil() async {
        let callCid = "default:\(String.unique)"
        let creatorId = "creator"
        let acceptedParticipantId = "participant-1"

        let reason = subject.reason(
            callState: .dummy(
                call: .dummy(
                    cid: callCid,
                    createdBy: .dummy(id: creatorId),
                    session: .dummy(
                        acceptedBy: [acceptedParticipantId: Date()],
                        rejectedBy: [creatorId: Date()]
                    )
                ),
                members: [
                    .dummy(userId: creatorId),
                    .dummy(userId: acceptedParticipantId),
                    .dummy(userId: mockStreamVideo.user.id)
                ]
            )
        )

        XCTAssertNil(reason)
    }

    func test_handledCallReason_givenAllOtherParticipantsRejected_thenReturnsAllOtherParticipantsRejectedReason() async {
        let callCid = "default:\(String.unique)"
        let creatorId = "creator"

        let reason = subject.reason(
            callState: .dummy(
                call: .dummy(
                    cid: callCid,
                    createdBy: .dummy(id: creatorId),
                    session: .dummy(
                        rejectedBy: [
                            "participant-1": Date(),
                            "participant-2": Date()
                        ]
                    )
                ),
                members: [
                    .dummy(userId: creatorId),
                    .dummy(userId: "participant-1"),
                    .dummy(userId: "participant-2"),
                    .dummy(userId: mockStreamVideo.user.id)
                ]
            )
        )

        XCTAssertEqual(
            reason,
            StreamRejectionReasonProvider.HandledCallReason.allOtherParticipantsRejected.rawValue
        )
    }
}
