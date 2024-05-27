//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation
@testable import StreamVideo
import XCTest

final class CallKitServiceTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: CallKitService! = .init()
    private lazy var callController: MockCXCallController! = .init()
    private lazy var callProvider: MockCXProvider! = .init()
    private lazy var user: User! = .init(id: "test")
    private lazy var cid: String! = "default:\(callId)"
    private var callId: String = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(10))
    private var localizedCallerName: String! = "Test Caller"
    private var callerId: String! = "test@example.com"
    private lazy var mockedStreamVideo: MockStreamVideo! = MockStreamVideo(
        stubbedProperty: [
            MockStreamVideo.propertyKey(for: \.state): MockStreamVideo.State(user: user)
        ],
        user: user
    )
    private lazy var defaultGetCallResponse: GetCallResponse! = .dummy(
        call: .dummy(
            cid: cid,
            id: callId,
            settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
            type: .default
        )
    )

    override func setUp() {
        super.setUp()
        subject.callController = callController
        subject.callProvider = callProvider
        callProvider.setDelegate(subject, queue: nil)
    }

    override func tearDown() {
        subject = nil
        callController = nil
        callProvider = nil
        user = nil
        cid = nil
        mockedStreamVideo = nil
        localizedCallerName = nil
        callerId = nil
        super.tearDown()
    }

    // MARK: - reportIncomingCall

    @MainActor
    func test_reportIncomingCall_callProviderWasCalledWithExpectedValues() {
        // Given
        let expectation = self.expectation(description: "Report Incoming Call")
        var completionError: Error?

        // When
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { error in
            completionError = error
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertNil(completionError)
        XCTAssertTrue(callProvider.reportNewIncomingCallCalled)
        XCTAssertEqual(callProvider.reportNewIncomingCallUpdate?.localizedCallerName, localizedCallerName)
        XCTAssertEqual(callProvider.reportNewIncomingCallUpdate?.remoteHandle?.value, callerId)
    }

    func test_reportIncomingCall_streamVideoIsNil_noCallWasCreatedAndNoActionIsBeingPerformed() async throws {
        try await assertWithoutRequestTransaction {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    @MainActor
    func test_reportIncomingCall_streamVideoDisconnectedAndThrowsError_callWasEnded() async throws {
        struct ConnectionError: Error {}
        stubConnectionState(to: .disconnected(error: nil))
        mockedStreamVideo.stub(for: .connect, with: ConnectionError())
        _ = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsAccepted_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasAccepted: true)
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsRejected_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasRejected: true)
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsRejectedByEveryoneElse_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasRejectedByEveryoneElse: true)
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsAccepted_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasAccepted: true)
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsRejected_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasRejected: true)
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsRejectedByEveryoneElse_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasRejectedByEveryoneElse: true)
    }

    @MainActor
    func test_reportIncomingCall_ringingTimeElapsed_callWasEnded() async throws {
        let ringingTimeoutSeconds = 1
        stubCall(
            response: .dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    settings: .dummy(
                        ring: .dummy(autoCancelTimeoutMs: ringingTimeoutSeconds * 1000)
                    ),
                    type: .default
                )
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }

            let waitExpectation = self.expectation(description: "Wait expectation")
            waitExpectation.isInverted = true
            wait(for: [waitExpectation], timeout: TimeInterval(ringingTimeoutSeconds * 2))
        }
    }

    @MainActor
    func test_reportIncomingCall_stateIsIdleAndCallWasAlreadyHandled_callWasEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    session: .dummy(acceptedBy: [user.id: Date()]),
                    settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
                    type: .default
                ),
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    @MainActor
    func test_reportIncomingCall_stateIsNotIdle_callWasEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))),
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertWithoutRequestTransaction {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }

            let waitExpectationA = self.expectation(description: "a")
            waitExpectationA.isInverted = true
            wait(for: [waitExpectationA], timeout: 3)

            /// Receive another call while we are ringing the first one
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    // MARK: - callAccepted

    @MainActor
    func test_callAccepted_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXAnswerCallAction.self) {
            subject.callAccepted(
                .dummy(
                    call: .dummy(
                        cid: cid,
                        id: callId,
                        type: .default
                    ),
                    callCid: cid
                )
            )
        }
    }

    // MARK: - callRejected

    @MainActor
    func test_callRejected_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callRejected(
                .dummy(
                    call: .dummy(id: callId),
                    callCid: cid,
                    user: .dummy(id: user.id)
                )
            )
        }
    }

    @MainActor
    func test_callRejected_whileInCall_expectedTransactionWasRequestedAndRemainsInCall() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXAnswerCallAction.self) {
            subject.callAccepted(
                .dummy(
                    call: .dummy(id: callId),
                    callCid: cid
                )
            )
        }

        XCTAssertEqual(subject.storage.count, 1)

        // Stub with the new call
        let secondCallId = "default:test-call-2"
        stubCall(overrideCallId: secondCallId, response: .dummy(
            call: .dummy(
                cid: callCid(from: secondCallId, callType: .default),
                id: secondCallId,
                settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
                type: .default
            )
        ))

        subject.reportIncomingCall(
            secondCallId,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        XCTAssertEqual(subject.storage.count, 2)

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callRejected(
                .dummy(
                    call: .dummy(id: secondCallId),
                    callCid: callCid(from: secondCallId, callType: .default),
                    user: .dummy(id: user.id)
                )
            )
        }

        await fulfillment { [weak subject] in subject?.storage.count == 1 }

        XCTAssertEqual(subject.storage.count, 1)
    }

    // MARK: - callEnded

    @MainActor
    func test_callEnded_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callEnded(cid)
        }
    }

    // MARK: - callParticipantLeft

    @MainActor
    func test_callParticipantLeft_participantsLeftMoreThanOne_callWasNotEnded() async throws {
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXAnswerCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }

            let waitExpectation = expectation(description: "Wait expectation.")
            waitExpectation.isInverted = true
            wait(for: [waitExpectation], timeout: 2)

            subject.callAccepted(
                .dummy(
                    call: .dummy(id: callId),
                    callCid: cid
                )
            )
        }

        let callState = CallState()
        callState.participants = [.dummy(), .dummy()]
        call.stub(for: \.state, with: callState)
        try await assertNotRequestTransaction(CXEndCallAction.self) {
            subject.callParticipantLeft(.dummy())
        }
    }

    @MainActor
    func test_callParticipantLeft_participantsLeftOnlyOne_callNotEnded() async throws {
        let call = stubCall(
            response: .dummy(
                call: defaultGetCallResponse.call,
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXAnswerCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }

            let waitExpectation = expectation(description: "Wait expectation.")
            waitExpectation.isInverted = true
            wait(for: [waitExpectation], timeout: 2)

            subject.callAccepted(.dummy(call: .dummy(id: callId), callCid: cid))
            subject.provider(callProvider, perform: CXAnswerCallAction(call: UUID()))

            let waitExpectation2 = expectation(description: "Wait expectation.")
            waitExpectation2.isInverted = true
            wait(for: [waitExpectation2], timeout: 2)
        }

        let callState = CallState()
        callState.participants = [.dummy()]
        call.stub(for: \.state, with: callState)

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callParticipantLeft(.dummy(callCid: cid))
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func assertRequestTransaction<T>(
        _ expected: T.Type,
        actionBlock: @MainActor @Sendable() -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        callController.reset()

        actionBlock()

        await fulfillment(timeout: defaultTimeout) { self.callController.requestWasCalledWith?.0.actions.first != nil }

        let action = try XCTUnwrap(
            callController.requestWasCalledWith?.0.actions.first,
            file: file,
            line: line
        )
        XCTAssertTrue(
            action is T,
            "Action type is \(String(describing: type(of: action))) instead of \(String(describing: T.self))",
            file: file,
            line: line
        )

        if let answerAction = action as? CXAnswerCallAction {
            subject.provider(callProvider, perform: answerAction)
        } else if let endAction = action as? CXEndCallAction {
            subject.provider(callProvider, perform: endAction)
        }
    }

    private func assertNotRequestTransaction<T>(
        _ expected: T.Type,
        actionBlock: @Sendable() -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

        let action = try XCTUnwrap(callController.requestWasCalledWith?.0.actions.first)
        XCTAssertFalse(
            action is T,
            "Action type is \(String(describing: type(of: action))) instead of \(String(describing: T.self))"
        )
    }

    @MainActor
    private func assertWithoutRequestTransaction(
        actionBlock: @MainActor @Sendable() -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

        let action = callController.requestWasCalledWith?.0.actions.first
        XCTAssertNil(
            action,
            "Action type is \(String(describing: type(of: action))) instead of nil)"
        )
    }

    @MainActor
    private func assertCallWasHandled(
        otherMembers: [MemberResponse] = [.dummy()],
        wasAccepted: Bool = false,
        wasRejected: Bool = false,
        wasRejectedByEveryoneElse: Bool = false
    ) async throws {
        let acceptedBy = wasAccepted ? [user.id: Date()] : [:]
        let rejectedBy: [String: Date] = {
            if wasRejected {
                return [user.id: Date()]
            } else if wasRejectedByEveryoneElse {
                return otherMembers.reduce(into: [String: Date]()) { partialResult, otherMember in
                    partialResult[otherMember.userId] = .init()
                }
            } else {
                return [:]
            }
        }()
        stubCall(
            response: .dummy(
                call: .dummy(
                    session: .dummy(
                        acceptedBy: acceptedBy,
                        rejectedBy: rejectedBy
                    )
                ),
                members: otherMembers + [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    @MainActor
    private func assertParticipantLeft(
        remainingParticipants: Int = 0
    ) async throws {
        stubCall(
            response: .dummy(
                members: (0...remainingParticipants)
                    .map { _ in MemberResponse.dummy() } + [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo
    }

    private func waitExpectation(
        timeout: TimeInterval = defaultTimeout,
        description: String = "Wait expectation"
    ) async {
        let waitExpectation = expectation(description: description)
        waitExpectation.isInverted = true
        await safeFulfillment(of: [waitExpectation], timeout: timeout)
    }

    private func stubConnectionState(to status: ConnectionStatus) {
        let mockedState = mockedStreamVideo.state
        mockedState.connection = status
        mockedStreamVideo.stub(for: \.state, with: mockedState)
    }

    @MainActor
    @discardableResult
    private func stubCall(
        overrideCallId: String? = nil,
        response: GetCallResponse
    ) -> MockCall {
        let callId = overrideCallId ?? callId
        let call = MockCall(.dummy(callId: callId))
        call.stub(for: .get, with: response)
        call.stub(
            for: .join,
            with: JoinCallResponse.dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    type: .default
                )
            )
        )
        call.stub(for: .accept, with: AcceptCallResponse(duration: "0"))
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
        return call
    }
}
