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
    private lazy var cid: String = "default:\(callId)"
    private lazy var mockedStreamVideo: MockStreamVideo! = MockStreamVideo(
        stubbedProperty: [
            MockStreamVideo.propertyKey(for: \.state): MockStreamVideo.State(user: .dummy(id: "test"))
        ],
        user: .init(id: "test")
    )

    private var callId: String = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(10))
    private var localizedCallerName: String = "Test Caller"
    private var callerId: String = "test@example.com"

    override func setUp() {
        super.setUp()
        subject.callController = callController
        subject.callProvider = callProvider
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - reportIncomingCall

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

    func test_reportIncomingCall_streamVideoIsNil_callWasEnded() async throws {
        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    func test_reportIncomingCall_streamVideoDisconnectedAndThrowsError_callWasEnded() async throws {
        struct ConnectionError: Error {}
        stubConnectionState(to: .disconnected(error: nil))
        mockedStreamVideo.stub(for: .connect, with: ConnectionError())
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
        let call = MockCall(.dummy())
        let response = GetCallResponse(
            call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: ringingTimeoutSeconds * 1000))),
            duration: "100",
            members: [],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
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
        let call = MockCall(.dummy())
        let response = GetCallResponse(
            call: .dummy(
                session: .dummy(acceptedBy: [mockedStreamVideo.user.id: Date()]),
                settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))
            ),
            duration: "100",
            members: [],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
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
        let call = MockCall(.dummy())
        let response = GetCallResponse(
            call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))),
            duration: "100",
            members: [],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
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

    func test_callAccepted_expectedTransactionWasRequested() async throws {
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXAnswerCallAction.self) {
            subject.callAccepted(.dummy(call: .dummy(id: callId)))
        }
    }

    // MARK: - callRejected

    func test_callRejected_expectedTransactionWasRequest() async throws {
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callRejected(.dummy(call: .dummy(id: callId)))
        }
    }

    // MARK: - callEnded

    func test_callEnded_expectedTransactionWasRequest() async throws {
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callEnded()
        }
    }

    // MARK: - callParticipantLeft

    @MainActor
    func test_callParticipantLeft_participantsLeftMoreThanOne_callWasNotEnded() async throws {
        let call = MockCall(.dummy(callId: callId))
        let response = GetCallResponse(
            call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))),
            duration: "100",
            members: [],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
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

            subject.callAccepted(.dummy(call: .dummy(id: callId)))
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
        let call = MockCall(.dummy(callId: callId))
        let response = GetCallResponse(
            call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))),
            duration: "100",
            members: [],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: .accept, with: AcceptCallResponse(duration: "100"))
        call.stub(for: .join, with: JoinCallResponse.dummy())
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
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

            subject.callAccepted(.dummy(call: .dummy(id: callId)))
            subject.provider(callProvider, perform: CXAnswerCallAction(call: UUID()))

            let waitExpectation2 = expectation(description: "Wait expectation.")
            waitExpectation2.isInverted = true
            wait(for: [waitExpectation2], timeout: 2)
        }

        let callState = CallState()
        callState.participants = [.dummy()]
        call.stub(for: \.state, with: callState)

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callParticipantLeft(.dummy())
        }
    }

    // MARK: - Private Helpers

    private func makeStreamVideo() async throws -> StreamVideo {
        let userId = "test_user"

        let authenticationProvider = TestsAuthenticationProvider()
        let tokenResponse = try await authenticationProvider.authenticate(
            environment: "demo",
            baseURL: .init(string: "https://pronto.getstream.io/api/auth/create-token")!,
            userId: userId
        )

        let client = StreamVideo(
            apiKey: tokenResponse.apiKey,
            user: User(id: userId),
            token: .init(rawValue: tokenResponse.token)
        )

        try await client.connect()

        return client
    }

    private func assertRequestTransaction<T>(
        _ expected: T.Type,
        actionBlock: @Sendable() -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

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

    private func assertWithoutRequestTransaction(
        actionBlock: @Sendable() -> Void,
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
        let call = MockCall(.dummy())
        let acceptedBy = wasAccepted ? [mockedStreamVideo.state.user.id: Date()] : [:]
        let rejectedBy: [String: Date] = {
            if wasRejected {
                return [mockedStreamVideo.state.user.id: Date()]
            } else if wasRejectedByEveryoneElse {
                return otherMembers.reduce(into: [String: Date]()) { partialResult, otherMember in
                    partialResult[otherMember.userId] = .init()
                }
            } else {
                return [:]
            }
        }()

        let response = GetCallResponse(
            call: .dummy(
                session: .dummy(
                    acceptedBy: acceptedBy,
                    rejectedBy: rejectedBy
                )
            ),
            duration: "100",
            members: otherMembers + [.dummy(userId: mockedStreamVideo.state.user.id)],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId
            ) { _ in }
        }
    }

    private func assertParticipantLeft(
        remainingParticipants: Int = 0
    ) async throws {
        let call = MockCall(.dummy())
        let response = GetCallResponse(
            call: .dummy(),
            duration: "100",
            members: (0...remainingParticipants)
                .map { _ in MemberResponse.dummy() } + [.dummy(userId: mockedStreamVideo.state.user.id)],
            ownCapabilities: []
        )
        call.stub(for: .get, with: response)
        mockedStreamVideo.stub(for: .call, with: call)
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
}

// Mock Classes

private final class MockCXProvider: CXProvider {
    var reportNewIncomingCallCalled = false
    var reportNewIncomingCallUpdate: CXCallUpdate?

    convenience init() {
        self.init(configuration: .init(localizedName: "test"))
    }

    override func reportNewIncomingCall(
        with UUID: UUID,
        update: CXCallUpdate,
        completion: @escaping (Error?) -> Void
    ) {
        reportNewIncomingCallCalled = true
        reportNewIncomingCallUpdate = update
        completion(nil)
    }
}
