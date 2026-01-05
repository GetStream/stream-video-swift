//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class PermissionStore_MicrophoneMiddlewareTests: XCTestCase, @unchecked Sendable {

    private lazy var mockPermissionProvider: MockMicrophonePermissionProvider! = .init()
    private lazy var subject: PermissionStore.MicrophoneMiddleware! = .init(
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
            expected: .setMicrophonePermission(.granted)
        )
    }

    func test_setDispatcher_systemPermissionDenied_expectedActionWasFiredWithSystemPermission() async throws {
        try await assertSetDispatcher(
            stubbedResult: .denied,
            expected: .setMicrophonePermission(.denied)
        )
    }

    // MARK: - apply

    // MARK: requestMicrophonePermission

    func test_reducer_requestMicrophonePermission_permissionProviderWasCalled() throws {
        subject.apply(
            state: .initial,
            action: .requestMicrophonePermission,
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mockPermissionProvider.timesCalled(.requestPermission), 1)
    }

    func test_reducer_requestMicrophonePermission_true_dispatcherWasCalledWithExpectedPermission() async throws {
        try await assertRequestPermission(
            stubbedResult: true,
            expected: .setMicrophonePermission(.granted)
        )
    }

    func test_reducer_requestMicrophonePermission_false_dispatcherWasCalledWithExpectedPermission() async throws {
        try await assertRequestPermission(
            stubbedResult: false,
            expected: .setMicrophonePermission(.denied)
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
        mockPermissionProvider.stub(for: \.systemPermission, with: stubbedResult)
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

        subject.apply(
            state: .initial,
            action: .requestMicrophonePermission,
            file: #file,
            function: #function,
            line: #line
        )

        await safeFulfillment(of: [expectation], file: file, line: line)
    }
}
