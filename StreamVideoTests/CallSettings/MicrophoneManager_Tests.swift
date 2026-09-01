//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MicrophoneManager_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - toggle

    func test_initialStatusEnabled_toggle_statusDoesNotChangeUntilCallSettingsUpdate() async throws {
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

    func test_initialStatusDisabled_enable_statusDoesNotChangeUntilCallSettingsUpdate() async throws {
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

    func test_initialStatusEnabled_enable_controllerIsNotCalled() async throws {
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

    func test_initialStatusEnabled_disable_statusDoesNotChangeUntilCallSettingsUpdate() async throws {
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

    func test_initialStatusDisabled_disable_controllerIsNotCalled() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .disabled
        )

        try await subject.disable()

        XCTAssertEqual(subject.status, .disabled)
        XCTAssertEqual(callController.timesCalled(.changeAudioState), 0)
    }

    // MARK: - setAudioBitrateProfile

    func test_setAudioBitrateProfile_updatesPublishedValueOnSuccess() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        try await subject.setAudioBitrateProfile(.musicHighQuality)

        XCTAssertEqual(subject.audioBitrateProfile, .musicHighQuality)
        XCTAssertEqual(callController.timesCalled(.setAudioBitrateProfile), 1)
        XCTAssertEqual(
            callController
                .recordedInputPayload(AudioBitrateProfile.self, for: .setAudioBitrateProfile)?
                .first,
            .musicHighQuality
        )
    }

    func test_setAudioBitrateProfile_doesNotUpdatePublishedValueOnFailure() async throws {
        let callController = MockCallController()
        callController.stub(
            for: .setAudioBitrateProfile,
            with: ClientError("Hi-fi audio is not enabled on dashboard settings.")
        )
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        do {
            try await subject.setAudioBitrateProfile(.musicHighQuality)
            XCTFail("Expected setAudioBitrateProfile to throw.")
        } catch {
            XCTAssertEqual(subject.audioBitrateProfile, .voiceStandard)
            XCTAssertEqual(callController.timesCalled(.setAudioBitrateProfile), 1)
        }
    }

    func test_setAudioBitrateProfile_sameProfile_doesNotCallController() async throws {
        let callController = MockCallController()
        let subject = MicrophoneManager(
            callController: callController,
            initialStatus: .enabled
        )

        try await subject.setAudioBitrateProfile(.voiceStandard)

        XCTAssertEqual(callController.timesCalled(.setAudioBitrateProfile), 0)
    }
}
