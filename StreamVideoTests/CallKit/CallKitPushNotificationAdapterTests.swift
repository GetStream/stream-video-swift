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

    // MARK: - pushRegistry(_:didUpdate:for:)

    func test_pushRegistryDidUpdatePushCredentials_deviceTokenWasConfiguredCorrectly() {
        simulateDeviceTokenFetch("mockDeviceToken")

        XCTAssertEqual(subject.deviceToken, "6d6f636b446576696365546f6b656e")
    }

    // MARK: - pushRegistry(_:didInvalidatePushTokenFor:)

    func test_pushRegistryDidInvalidatePushCredentials_deviceTokenWasConfiguredCorrectly() {
        simulateDeviceTokenFetch("mockDeviceToken")

        subject.pushRegistry(
            subject.registry,
            didInvalidatePushTokenFor: .voIP
        )

        XCTAssertEqual(subject.deviceToken, "")
    }

    // MARK: - pushRegistry(_:didReceiveIncomingPushWith:for:completion:)

    func test_pushRegistryDidReceiveIncomingPush_typeIsVoIP_reportIncomingCallWasCalledAsExpected() {
        let pushPayload = MockPKPushPayload()
        pushPayload.stubType = .voIP
        pushPayload.stubDictionaryPayload = [
            "stream": [
                "call_cid": "123",
                "created_by_display_name": "TestUser",
                "created_by_id": "test_user"
            ]
        ]

        let completionWasCalledExpectation = expectation(description: "Completion was called.")
        subject.pushRegistry(
            subject.registry,
            didReceiveIncomingPushWith: pushPayload,
            for: pushPayload.type,
            completion: { completionWasCalledExpectation.fulfill() }
        )

        XCTAssertEqual(callKitService.reportIncomingCallWasCalled?.cid, "123")
        XCTAssertEqual(callKitService.reportIncomingCallWasCalled?.callerName, "TestUser")
        XCTAssertEqual(callKitService.reportIncomingCallWasCalled?.callerId, "test_user")
        callKitService.reportIncomingCallWasCalled?.completion(nil)

        wait(for: [completionWasCalledExpectation], timeout: defaultTimeout)
    }

    func test_pushRegistryDidReceiveIncomingPush_typeIsNotVoIP_reportIncomingCallWasNotCalled() {
        let pushPayload = MockPKPushPayload()
        pushPayload.stubType = .fileProvider
        pushPayload.stubDictionaryPayload = [:]

        subject.pushRegistry(
            subject.registry,
            didReceiveIncomingPushWith: pushPayload,
            for: pushPayload.type,
            completion: {}
        )

        XCTAssertNil(callKitService.reportIncomingCallWasCalled)
    }

    // MARK: - Private helpers

    private func simulateDeviceTokenFetch(_ token: String) {
        let registry = subject.registry
        let deviceToken = token.data(using: .utf8)!
        let stubPushCredentials = MockPKPushCredentials()
        stubPushCredentials.stubType = .voIP
        stubPushCredentials.stubToken = deviceToken

        subject.pushRegistry(
            registry,
            didUpdate: stubPushCredentials,
            for: .voIP
        )
    }
}

// MARK: - Mocks

private final class MockPKPushCredentials: PKPushCredentials {

    var stubType: PKPushType = .voIP
    var stubToken: Data!

    override var type: PKPushType { stubType }
    override var token: Data { stubToken }
}

private final class MockPKPushPayload: PKPushPayload {

    var stubType: PKPushType = .voIP
    var stubDictionaryPayload: [AnyHashable: Any] = [:]

    override var type: PKPushType { stubType }
    override var dictionaryPayload: [AnyHashable: Any] { stubDictionaryPayload }
}
