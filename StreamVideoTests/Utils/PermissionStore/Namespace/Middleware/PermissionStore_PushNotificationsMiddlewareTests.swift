//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import UserNotifications
import XCTest

final class PermissionStore_PushNotificationsMiddlewareTests: XCTestCase, @unchecked Sendable {

    private lazy var mockPermissionProvider: MockPushNotificationsPermissionProvider! = .init()
    private lazy var subject: PermissionStore.PushNotificationsMiddleware! = .init(
        permissionProvider: mockPermissionProvider
    )

    override func tearDown() {
        mockPermissionProvider = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - setDispatcher

    func test_setDispatcher_systemPermissionGranted_expectedActionWasFiredWithSystemPermission() async throws {
        try await assertSetDispatcher(
            stubbedResult: .granted,
            expected: .setPushNotificationPermission(.granted)
        )
    }

    func test_setDispatcher_systemPermissionDenied_expectedActionWasFiredWithSystemPermission() async throws {
        try await assertSetDispatcher(
            stubbedResult: .denied,
            expected: .setPushNotificationPermission(.denied)
        )
    }

    // MARK: - apply

    // MARK: requestPushNotificationsPermission

    func test_reducer_requestPushNotificationsPermission_permissionProviderWasCalled() throws {
        subject.apply(
            state: .initial,
            action: .requestPushNotificationPermission([]),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mockPermissionProvider.timesCalled(.requestPermission), 1)
    }

    func test_reducer_requestPushNotificationsPermission_true_dispatcherWasCalledWithExpectedPermission() async throws {
        try await assertRequestPermission(
            options: [.alert],
            stubbedResult: true,
            expected: .setPushNotificationPermission(.granted)
        )
    }

    func test_reducer_requestPushNotificationsPermission_false_dispatcherWasCalledWithExpectedPermission() async throws {
        try await assertRequestPermission(
            options: [.badge, .carPlay],
            stubbedResult: false,
            expected: .setPushNotificationPermission(.denied)
        )
    }

    // MARK: - Private Helpers

    private func assertSetDispatcher(
        stubbedResult: PermissionStore.Permission,
        expected: PermissionStore.StoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        await wait(for: 1.0)
        mockPermissionProvider.stub(for: .systemPermission, with: stubbedResult)
        let expectation = self.expectation(description: "\(expected) was dispatched.")
        subject.dispatcher = .init { actions, _, _, _ in
            guard actions.first?.wrappedValue == expected else {
                return
            }
            expectation.fulfill()
        }

        await safeFulfillment(of: [expectation], file: file, line: line)
    }

    private func assertRequestPermission(
        options: UNAuthorizationOptions,
        stubbedResult: Bool,
        expected: PermissionStore.StoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        mockPermissionProvider.stub(for: .requestPermission, with: stubbedResult)
        let expectation = self.expectation(description: "\(expected) was dispatched.")
        subject.dispatcher = .init { actions, _, _, _ in
            guard actions.first?.wrappedValue == expected else {
                return
            }
            expectation.fulfill()
        }
        await wait(for: 1.0)

        subject.apply(
            state: .initial,
            action: .requestPushNotificationPermission(options),
            file: #file,
            function: #function,
            line: #line
        )

        await safeFulfillment(of: [expectation], file: file, line: line)
        XCTAssertEqual(
            mockPermissionProvider.timesCalled(.requestPermission),
            1,
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockPermissionProvider.recordedInputPayload(UNAuthorizationOptions.self, for: .requestPermission)?.last,
            options,
            file: file,
            line: line
        )
    }
}
