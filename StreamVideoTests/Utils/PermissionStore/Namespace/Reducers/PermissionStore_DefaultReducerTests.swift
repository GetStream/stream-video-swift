//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class PermissionStore_DefaultReducerTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: PermissionStore.DefaultReducer! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - reduce

    // MARK: setMicrophonePermission

    func test_reducer_setMicrophonePermission_granted_returnsExpectedState() async throws {
        try await assertState(
            action: .setMicrophonePermission(.granted),
            validation: { $0.microphonePermission == .granted }
        )
    }

    func test_reducer_setMicrophonePermission_denied_returnsExpectedState() async throws {
        try await assertState(
            action: .setMicrophonePermission(.denied),
            validation: { $0.microphonePermission == .denied }
        )
    }

    // MARK: requestMicrophonePermission

    func test_reducer_requestMicrophonePermission_returnsExpectedState() async throws {
        try await assertState(
            action: .requestMicrophonePermission,
            validation: { $0.microphonePermission == .requesting }
        )
    }

    // MARK: setCameraPermission

    func test_reducer_setCameraPermission_granted_returnsExpectedState() async throws {
        try await assertState(
            action: .setCameraPermission(.granted),
            validation: { $0.cameraPermission == .granted }
        )
    }

    func test_reducer_setCameraPermission_denied_returnsExpectedState() async throws {
        try await assertState(
            action: .setCameraPermission(.denied),
            validation: { $0.cameraPermission == .denied }
        )
    }

    // MARK: requestCameraPermission

    func test_reducer_requestCameraPermission_returnsExpectedState() async throws {
        try await assertState(
            action: .requestCameraPermission,
            validation: { $0.cameraPermission == .requesting }
        )
    }

    // MARK: setPushNotificationPermission

    func test_reducer_setPushNotificationPermission_granted_returnsExpectedState() async throws {
        try await assertState(
            action: .setPushNotificationPermission(.granted),
            validation: { $0.pushNotificationPermission == .granted }
        )
    }

    func test_reducer_setPushNotificationPermission_denied_returnsExpectedState() async throws {
        try await assertState(
            action: .setPushNotificationPermission(.denied),
            validation: { $0.pushNotificationPermission == .denied }
        )
    }

    // MARK: requestPushNotificationPermission

    func test_reducer_requestPushNotificationPermission_returnsExpectedState() async throws {
        try await assertState(
            action: .requestPushNotificationPermission([]),
            validation: { $0.pushNotificationPermission == .requesting }
        )
    }

    // MARK: - Private Helpers

    private func assertState(
        action: PermissionStore.Namespace.Action,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        validation: (PermissionStore.Namespace.State) -> Bool
    ) async throws {
        let actual = try await subject.reduce(
            state: .initial,
            action: action,
            file: file,
            function: function,
            line: line
        )

        XCTAssertTrue(validation(actual), file: file, line: line)
    }
}
