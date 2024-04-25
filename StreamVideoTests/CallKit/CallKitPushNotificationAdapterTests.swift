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
        assertDidReceivePushNotification(
            .init(
                cid: "123",
                localizedCallerName: "TestUser",
                callerId: "test_user"
            )
        )
    }

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

    func test_pushRegistryDidReceiveIncomingPush_typeIsNotVoIP_reportIncomingCallWasNotCalled() {
        assertDidReceivePushNotification(contentType: .fileProvider)
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
