//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import PushKit
@testable import StreamVideo
import XCTest

final class CallKitPushNotificationAdapterTests: XCTestCase {

    private lazy var callKitService: MockCallKitService! = .init()
    private lazy var subject: CallKitPushNotificationAdapter! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        InjectedValues[\.callKitService] = callKitService
    }

    override func tearDown() {
        callKitService = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - register

    func test_register_registryWasConfiguredCorrectly() {
        subject.register()

        XCTAssertTrue(subject.registry.delegate === subject)
        XCTAssertEqual(subject.registry.desiredPushTypes, [.voIP])
    }

    // MARK: - unregister

    func test_unregister_registryWasConfiguredCorrectly() {
        subject.register()

        subject.unregister()

        XCTAssertNil(subject.registry.delegate)
        XCTAssertTrue(subject.registry.desiredPushTypes?.isEmpty ?? false)
    }

    func test_unregister_deviceTokenWasConfiguredCorrectly() {
        let expectedDecodedToken = "test-device-token"
        subject.register()
        subject.pushRegistry(
            subject.registry,
            didUpdate: .dummy(expectedDecodedToken),
            for: .voIP
        )

        XCTAssertEqual(subject.deviceToken.decodedHex, expectedDecodedToken)
        subject.unregister()

        XCTAssertTrue(subject.deviceToken.isEmpty)
    }

    // MARK: - pushRegistry(_:didUpdate:for:)

    func test_pushRegistryDidUpdatePushCredentials_deviceTokenWasConfiguredCorrectly() {
        let expected = "mock-device-token"
        subject.pushRegistry(
            subject.registry,
            didUpdate: .dummy(expected),
            for: .voIP
        )

        XCTAssertEqual(subject.deviceToken.decodedHex, expected)
    }

    // MARK: - pushRegistry(_:didInvalidatePushTokenFor:)

    func test_pushRegistryDidInvalidatePushCredentials_deviceTokenWasConfiguredCorrectly() {
        let expected = "mock-device-token"
        subject.pushRegistry(
            subject.registry,
            didUpdate: .dummy(expected),
            for: .voIP
        )

        subject.pushRegistry(
            subject.registry,
            didInvalidatePushTokenFor: .voIP
        )

        XCTAssertTrue(subject.deviceToken.isEmpty)
    }

    // MARK: - pushRegistry(_:didReceiveIncomingPushWith:for:completion:)

    @MainActor
    func test_pushRegistryDidReceiveIncomingPush_typeIsVoIP_reportIncomingCallWasCalledAsExpected() {
        assertDidReceivePushNotification(
            .init(
                cid: "123",
                localizedCallerName: "TestUser",
                callerId: "test_user"
            )
        )
    }

    @MainActor
    func test_pushRegistryDidReceiveIncomingPush_typeIsVoIPWithDisplayNameAndCallerName_reportIncomingCallWasCalledAsExpected() {
        assertDidReceivePushNotification(
            .init(
                cid: "123",
                localizedCallerName: "TestUser",
                callerId: "test_user"
            ),
            displayName: "Stream Group Call"
        )
    }

    @MainActor
    func test_pushRegistryDidReceiveIncomingPush_typeIsNotVoIP_reportIncomingCallWasNotCalled() {
        assertDidReceivePushNotification(contentType: .fileProvider)
    }

    // MARK: - Private helpers

    @MainActor
    private func assertDidReceivePushNotification(
        _ content: CallKitPushNotificationAdapter.Content? = nil,
        contentType: PKPushType = .voIP,
        displayName: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let pushPayload = MockPKPushPayload()
        pushPayload.stubType = contentType
        pushPayload.stubDictionaryPayload = content.map { [
            "stream": [
                "call_cid": $0.cid,
                "call_display_name": displayName,
                "created_by_display_name": $0.localizedCallerName,
                "created_by_id": $0.callerId
            ]
        ] } ?? [:]

        let completionWasCalledExpectation = expectation(description: "Completion was called.")
        completionWasCalledExpectation.isInverted = content == nil
        subject.pushRegistry(
            subject.registry,
            didReceiveIncomingPushWith: pushPayload,
            for: pushPayload.type,
            completion: { completionWasCalledExpectation.fulfill() }
        )

        if let content {
            XCTAssertEqual(
                callKitService.reportIncomingCallWasCalled?.cid,
                content.cid,
                file: file,
                line: line
            )
            XCTAssertEqual(
                callKitService.reportIncomingCallWasCalled?.callerName,
                displayName.isEmpty ? content.localizedCallerName : displayName,
                file: file,
                line: line
            )
            XCTAssertEqual(
                callKitService.reportIncomingCallWasCalled?.callerId,
                content.callerId,
                file: file,
                line: line
            )
            callKitService.reportIncomingCallWasCalled?.completion(nil)
        } else {
            XCTAssertNil(
                callKitService.reportIncomingCallWasCalled,
                file: file,
                line: line
            )
        }

        wait(for: [completionWasCalledExpectation], timeout: defaultTimeout)
    }
}

// MARK: - Mocks

private final class MockPKPushPayload: PKPushPayload {

    var stubType: PKPushType = .voIP
    var stubDictionaryPayload: [AnyHashable: Any] = [:]

    override var type: PKPushType { stubType }
    override var dictionaryPayload: [AnyHashable: Any] { stubDictionaryPayload }
}

private extension PKPushCredentials {
    private final class MockPKPushCredentials: PKPushCredentials {
        private let inputToken: Data
        override var token: Data { inputToken }
        init(_ input: String) {
            inputToken = Data(input.utf8)
            super.init()
        }
    }

    static func dummy(_ token: String) -> PKPushCredentials {
        MockPKPushCredentials(token)
    }
}

private extension String {
    var decodedHex: String {
        var data = Data()
        var currentIndex = startIndex

        // Ensure the string has an even number of characters
        guard count % 2 == 0 else { return "self" }

        while currentIndex < endIndex {
            let nextIndex = index(currentIndex, offsetBy: 2)
            let byteString = self[currentIndex..<nextIndex]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return self
            }
            currentIndex = nextIndex
        }

        return String(data: data, encoding: .utf8) ?? self
    }
}
