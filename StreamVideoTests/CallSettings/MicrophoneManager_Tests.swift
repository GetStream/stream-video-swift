//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MicrophoneManager_Tests: XCTestCase, @unchecked Sendable {

    func test_microphoneManager_toggle() async throws {
        try await assertStatus(
            .disabled,
            initialStatus: .enabled,
            action: { try await $0.toggle() }
        )
    }

    func test_microphoneManager_enable() async throws {
        try await assertStatus(
            .enabled,
            initialStatus: .disabled,
            action: { try await $0.enable() }
        )
    }

    func test_microphoneManager_disable() async throws {
        try await assertStatus(
            .disabled,
            initialStatus: .enabled,
            action: { try await $0.disable() }
        )
    }

    func test_microphoneManager_sameState() async throws {
        try await assertStatus(
            .enabled,
            initialStatus: .enabled,
            action: { try await $0.enable() }
        )
    }

    // MARK: - Private helpers

    private func assertStatus(
        _ expected: CallSettingsStatus,
        initialStatus: CallSettingsStatus,
        action: @escaping (MicrophoneManager) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            initialStatus: initialStatus
        )

        // When
        try await action(microphoneManager)

        // Then
        XCTAssert(microphoneManager.status == expected)
    }
}
