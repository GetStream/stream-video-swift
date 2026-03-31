//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MicrophoneManager_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - toggle

    func test_initialStatusEnabled_whenToggle_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        try await subject.toggle()

        XCTAssertEqual(subject.status, .enabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeAudioState)?
                .first,
            false
        )
    }

    // MARK: - enable

    func test_initialStatusDisabled_whenEnable_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .disabled
        )

        try await subject.enable()

        XCTAssertEqual(subject.status, .disabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeAudioState)?
                .first,
            true
        )
    }

    func test_initialStatusEnabled_whenEnable_thenControllerIsNotCalled() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        try await subject.enable()

        XCTAssertEqual(subject.status, .enabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 0)
    }

    // MARK: - disable

    func test_initialStatusEnabled_whenDisable_thenStatusDoesNotChangeUntilCallSettingsUpdate() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        try await subject.disable()

        XCTAssertEqual(subject.status, .enabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(Bool.self, for: .changeAudioState)?
                .first,
            false
        )
    }

    func test_initialStatusDisabled_whenDisable_thenControllerIsNotCalled() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .disabled
        )

        try await subject.disable()

        XCTAssertEqual(subject.status, .disabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 0)
    }
}
