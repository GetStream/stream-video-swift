//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MicrophoneManager_Tests: XCTestCase, @unchecked Sendable {

    private lazy var initialStatus: CallSettingsStatus! = .enabled
    private lazy var mockCallController: MockCallController! = .init()
    private lazy var subject: MicrophoneManager! = MicrophoneManager(
        callController: mockCallController,
        initialStatus: initialStatus
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        mockCallController = nil
        initialStatus = nil
        super.tearDown()
    }

    // MARK: - toggle

    func test_microphoneManager_toggle() async throws {
        try await assertStatus(
            .disabled,
            initialStatus: .enabled,
            action: { try await $0.toggle() }
        )
    }

    // MARK: - enable

    func test_microphoneManager_enable() async throws {
        try await assertStatus(
            .enabled,
            initialStatus: .disabled,
            action: { try await $0.enable() }
        )
    }

    // MARK: - disable

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
    
    // MARK: - setHiFiEnabled
    
    func test_setHiFiEnabled_true_correctlyUpdatesStateAdapter() async throws {
        await subject.setHiFiEnabled(true)

        XCTAssertEqual(mockCallController.recordedInputPayload(Bool.self, for: .setHiFiEnabled)?.first, true)
    }
    
    func test_setHiFiEnabled_false_correctlyUpdatesStateAdapter() async throws {
        await subject.setHiFiEnabled(false)

        XCTAssertEqual(mockCallController.recordedInputPayload(Bool.self, for: .setHiFiEnabled)?.first, false)
    }
    
    // MARK: - Private helpers
    
    private func assertStatus(
        _ expected: CallSettingsStatus,
        initialStatus: CallSettingsStatus,
        action: @escaping (MicrophoneManager) async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        self.initialStatus = initialStatus

        // When
        try await action(subject)

        // Then
        XCTAssertEqual(subject.status, expected, file: file, line: line)
    }
}
