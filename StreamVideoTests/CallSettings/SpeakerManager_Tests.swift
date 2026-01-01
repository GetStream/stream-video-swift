//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class SpeakerManager_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - disable

    func test_speaker_disable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )

        // When
        try await speakerManager.disableSpeakerPhone()

        // Then
        XCTAssert(speakerManager.status == .disabled)
    }

    // MARK: - enable

    func test_speaker_enable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .disabled,
            initialAudioOutputStatus: .enabled
        )

        // When
        try await speakerManager.enableSpeakerPhone()

        // Then
        XCTAssert(speakerManager.status == .enabled)
    }

    // MARK: - disableAudioOutput

    func test_speaker_disableAudioOutput() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )

        // When
        try await speakerManager.disableAudioOutput()

        // Then
        XCTAssert(speakerManager.audioOutputStatus == .disabled)
    }

    // MARK: - enableAudioOutput

    func test_speaker_enableAudioOutput() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .disabled
        )

        // When
        try await speakerManager.enableAudioOutput()

        // Then
        XCTAssert(speakerManager.audioOutputStatus == .enabled)
    }

    // MARK: - didUpdate callSettings

    @MainActor
    func test_didUpdateCall_updatesStatus() async throws {
        // Given
        let streamVideo = MockStreamVideo()
        _ = streamVideo
        let call = Call.dummy()

        await wait(for: 0.5)
        call.state.update(callSettings: .init(speakerOn: false, audioOutputOn: false))

        await fulfillment {
            call.speaker.status == .disabled
                && call.speaker.audioOutputStatus == .disabled
        }
    }

    @MainActor
    func test_toggleSpeaker_afterDidUpdateCall_updatesCorrectly() async throws {
        // Given
        let streamVideo = MockStreamVideo()
        _ = streamVideo
        let call = Call.dummy()
        await wait(for: 0.5)
        await fulfilmentInMainActor { call.speaker.status == .enabled && call.speaker.status == .enabled }
        call.state.update(callSettings: .init(speakerOn: false, audioOutputOn: false))
        await fulfilmentInMainActor { call.speaker.status == .disabled && call.speaker.status == .disabled }

        try await call.speaker.toggleSpeakerPhone()

        await fulfilmentInMainActor { call.speaker.status == .enabled }
    }
}
