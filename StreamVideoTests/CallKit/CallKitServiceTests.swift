//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation
@testable import StreamVideo
import XCTest

final class CallKitServiceTests: XCTestCase {

    private lazy var subject: CallKitService! = .init()
    private lazy var callController: MockCXCallController! = .init()
    private lazy var callProvider: MockCXProvider! = .init()
    private lazy var cid: String = "default:\(callId)"

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

    // MARK: - callAccepted

    func test_callAccepted_expectedTransactionWasRequest() async throws {
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
        actionBlock: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

        let action = try XCTUnwrap(callController.requestWasCalledWith?.0.actions.first)
        XCTAssertTrue(
            action is T,
            "Action type is \(String(describing: type(of: action))) instead of \(String(describing: T.self))"
        )
    }

    private func waitExpectation(
        timeout: TimeInterval = defaultTimeout,
        description: String = "Wait expectation"
    ) async {
        let waitExpectation = expectation(description: description)
        waitExpectation.isInverted = true
        await safeFulfillment(of: [waitExpectation], timeout: timeout)
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

private final class MockCXCallController: CXCallController {
    private(set) var requestWasCalledWith: (CXTransaction, (Error?) -> Void)?

    override func request(
        _ transaction: CXTransaction,
        completion: @escaping ((any Error)?) -> Void
    ) {
        requestWasCalledWith = (transaction, completion)
    }

    override func requestTransaction(with action: CXAction) async throws {
        requestWasCalledWith = (.init(action: action), { _ in })
    }
}
