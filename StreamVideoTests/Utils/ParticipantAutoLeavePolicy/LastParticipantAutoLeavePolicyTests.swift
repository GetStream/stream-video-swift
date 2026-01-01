//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import XCTest

final class LastParticipantAutoLeavePolicyTests: XCTestCase, @unchecked Sendable {

    private lazy var user: User! = .dummy()
    private lazy var mockStreamVideo: MockStreamVideo! = MockStreamVideo(
        stubbedProperty: [
            MockStreamVideo.propertyKey(for: \.state): MockStreamVideo.State(user: user)
        ],
        user: user
    )
    private lazy var subject: LastParticipantAutoLeavePolicy! = .init()

    override func setUp() {
        super.setUp()
        _ = mockStreamVideo
    }

    override func tearDown() {
        user = nil
        mockStreamVideo = nil
        subject = nil
        super.tearDown()
    }

    func test_ringingCallAndActiveCallUpdates_maxParticipantsWasMoreThanOne_whenParticipantCountBecomesOneTriggersPolicy() async {
        await assertPolicyWasTriggered(
            true,
            ringingCall: .dummy(callType: .default, callId: "123"),
            activeCall: .dummy(callType: .default, callId: "123"),
            maxParticipantsCount: 3,
            currentParticipantsCount: 1,
            acceptedBy: 2
        )
    }

    func test_ringingCallAndActiveCallUpdates_maxParticipantsWasNotMoreThanOne_whenParticipantCountBecomesOneDoesNotTriggerPolicy(
    ) async {
        await assertPolicyWasTriggered(
            false,
            ringingCall: .dummy(callType: .default, callId: "123"),
            activeCall: .dummy(callType: .default, callId: "123"),
            maxParticipantsCount: 1,
            currentParticipantsCount: 1,
            acceptedBy: 1
        )
    }

    func test_ringingCallAndActiveCallUpdates_maxParticipantsWasMoreThanOneNotAcceptedBy_whenParticipantCountBecomesOneDoesNotTriggerPolicy(
    ) async {
        await assertPolicyWasTriggered(
            false,
            ringingCall: .dummy(callType: .default, callId: "123"),
            activeCall: .dummy(callType: .default, callId: "123"),
            maxParticipantsCount: 2,
            currentParticipantsCount: 1,
            acceptedBy: 0
        )
    }

    func test_ringingCallAndActiveCallUpdatesButAreDifferent_maxParticipantsWasMoreThanOne_whenParticipantCountBecomesOneDoesNotTriggerPolicy(
    ) async {
        await assertPolicyWasTriggered(
            false,
            ringingCall: .dummy(callType: .default, callId: "1234"),
            activeCall: .dummy(callType: .default, callId: "123"),
            maxParticipantsCount: 3,
            currentParticipantsCount: 1,
            acceptedBy: 2
        )
    }

    func test_noRingingCallAndActiveCallUpdates_maxParticipantsWasMoreThanOne_whenParticipantCountBecomesOneDoesNotTriggerPolicy(
    ) async {
        await assertPolicyWasTriggered(
            false,
            ringingCall: nil,
            activeCall: .dummy(callType: .default, callId: "123"),
            maxParticipantsCount: 3,
            currentParticipantsCount: 1,
            acceptedBy: 2
        )
    }

    // MARK: - Private helpers

    private func assertPolicyWasTriggered(
        _ expectsTrigger: Bool,
        ringingCall: Call?,
        activeCall: Call,
        maxParticipantsCount: Int,
        currentParticipantsCount: Int,
        acceptedBy: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let triggerExpectation = XCTestExpectation(description: "Policy was triggered!")
        triggerExpectation.isInverted = !expectsTrigger
        subject.onPolicyTriggered = { triggerExpectation.fulfill() }

        if let ringingCall {
            mockRingingCall(ringingCall)
            await fulfillment(file: file, line: line) { self.mockStreamVideo.state.ringingCall?.cId == ringingCall.cId }
        }

        mockActiveCall(activeCall)
        await fulfilmentInMainActor(file: file, line: line) { self.mockStreamVideo.state.activeCall?.cId == activeCall.cId }

        mockSessionAcceptedBy(acceptedBy, on: activeCall)
        await fulfilmentInMainActor(file: file, line: line) { activeCall.state.session?.acceptedBy.count == acceptedBy }

        mockParticipantsJoined(maxParticipantsCount, on: activeCall)
        await fulfilmentInMainActor(file: file, line: line) { activeCall.state.participantsMap.count == maxParticipantsCount }

        mockParticipantsJoined(currentParticipantsCount, on: activeCall)
        await fulfilmentInMainActor(file: file, line: line) { activeCall.state.participantsMap.count == currentParticipantsCount }

        await safeFulfillment(
            of: [triggerExpectation],
            timeout: expectsTrigger ? defaultTimeout : 5,
            file: file,
            line: line
        )
    }

    private func mockRingingCall(_ call: Call?) {
        mockStreamVideo.state.ringingCall = call
    }

    private func mockActiveCall(_ call: Call?) {
        mockStreamVideo.state.activeCall = call
    }

    private func mockParticipantsJoined(_ count: Int, on call: Call) {
        let participants = (0..<count)
            .map { _ in CallParticipant.dummy() }
            .reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }
        Task { @MainActor in
            call.state.participantsMap = participants
        }
    }

    private func mockSessionAcceptedBy(_ count: Int, on call: Call) {
        let acceptedBy = (0..<count)
            .map { _ in Date() }
            .reduce(into: [String: Date]()) { $0[.unique] = $1 }
        Task { @MainActor in
            call.state.session = .dummy(acceptedBy: acceptedBy)
        }
    }
}
