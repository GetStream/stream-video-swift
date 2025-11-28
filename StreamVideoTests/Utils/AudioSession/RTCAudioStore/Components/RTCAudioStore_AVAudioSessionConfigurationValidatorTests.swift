//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_AVAudioSessionConfigurationValidatorTests: XCTestCase,
    @unchecked Sendable {

    private var subject: RTCAudioStore.StoreState.AVAudioSessionConfiguration!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_allowedPlaybackConfiguration_isValid() {
        subject = .init(
            category: .playback,
            mode: .moviePlayback,
            options: [.mixWithOthers, .duckOthers],
            overrideOutputAudioPort: .speaker
        )

        XCTAssertTrue(subject.isValid)
    }

    func test_allowedPlayAndRecordConfiguration_isValid() {
        subject = .init(
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .defaultToSpeaker],
            overrideOutputAudioPort: .none
        )

        XCTAssertTrue(subject.isValid)
    }

    func test_unknownCategory_isInvalid() {
        subject = .init(
            category: AVAudioSession.Category(rawValue: "stream.video.tests.invalid"),
            mode: .default,
            options: [],
            overrideOutputAudioPort: .speaker
        )

        XCTAssertFalse(subject.isValid)
    }

    func test_playbackWithUnsupportedMode_isInvalid() {
        subject = .init(
            category: .playback,
            mode: .voiceChat,
            options: [.mixWithOthers],
            overrideOutputAudioPort: .none
        )

        XCTAssertFalse(subject.isValid)
    }

    func test_playbackWithUnsupportedOptions_isInvalid() {
        subject = .init(
            category: .playback,
            mode: .default,
            options: [.allowBluetoothHFP],
            overrideOutputAudioPort: .speaker
        )

        XCTAssertFalse(subject.isValid)
    }
}
