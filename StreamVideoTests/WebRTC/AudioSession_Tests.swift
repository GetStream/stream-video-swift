//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioSession_Tests: XCTestCase {

    private lazy var subject: AudioSession! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - configure

    func test_configure_givenAudioOnAndSpeakerOn_whenConfiguring_thenAudioAndSpeakerAreEnabled() async {
        // When
        await subject.configure(audioOn: true, speakerOn: true)

        // Then
        XCTAssertTrue(RTCAudioSession.sharedInstance().isActive)
        XCTAssertTrue(AVAudioSession.sharedInstance().categoryOptions.contains(.defaultToSpeaker))
        XCTAssertEqual(AVAudioSession.sharedInstance().mode, .videoChat)
    }

    func test_configure_givenAudioOffAndSpeakerOff_whenConfiguring_thenAudioIsOffAndSpeakerNotEnabled() async {
        // When
        await subject.configure(audioOn: false, speakerOn: false)

        // Then
        XCTAssertFalse(RTCAudioSession.sharedInstance().isActive)
        XCTAssertFalse(AVAudioSession.sharedInstance().categoryOptions.contains(.defaultToSpeaker))
        XCTAssertEqual(AVAudioSession.sharedInstance().mode, .voiceChat)
    }

    func test_setAudioSessionEnabled_givenEnabledTrue_whenSettingAudioEnabled_thenAudioSessionIsEnabled() async {
        // When
        await subject.setAudioSessionEnabled(true)

        // Then
        XCTAssertTrue(RTCAudioSession.sharedInstance().isAudioEnabled)
    }

    // MARK: - deinit

    func test_deinit_givenAudioSession_whenDeinitialized_thenAudioSessionIsDisabled() async {
        _ = subject

        await subject.setAudioSessionEnabled(true)
        subject = nil

        // Then
        XCTAssertFalse(RTCAudioSession.sharedInstance().isAudioEnabled)
    }
}
