//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MusicCapturePolicy_Tests: XCTestCase, @unchecked Sendable {

    private var subject: MusicCapturePolicy!

    override func setUp() {
        super.setUp()
        subject = MusicCapturePolicy()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_needsCaptureApply_whenDesiredUnchangedAndApplied_returnsFalse() {
        XCTAssertFalse(subject.needsCaptureApply(desiredMusic: false))

        subject.setDesiredMusic(true, restorePlayout: false, isMuted: false)
        subject.markApplied(stereoPreferred: false)

        XCTAssertFalse(subject.needsCaptureApply(desiredMusic: true))
    }

    func test_needsCaptureApply_whenApplyDidNotStick_returnsTrue() {
        subject.setDesiredMusic(true, restorePlayout: false, isMuted: false)

        XCTAssertTrue(subject.needsCaptureApply(desiredMusic: true))
    }

    func test_needsCaptureApply_whenStereoPreferred_voiceDoesNotNeedApply() {
        XCTAssertFalse(subject.needsCaptureApply(desiredMusic: false))
        XCTAssertEqual(
            subject.configuration(stereoPreferred: true),
            .voiceWhileStereo
        )
        XCTAssertTrue(
            subject.bypassVoiceProcessing(stereoPreferred: true)
        )
        XCTAssertEqual(
            subject.muteMode(stereoPreferred: true),
            .inputMixer
        )
        XCTAssertFalse(
            subject.bypassVoiceProcessing(stereoPreferred: false)
        )
    }

    func test_configuration_musicDisablesVP_voiceWhileStereoKeepsVPDisabled() {
        XCTAssertEqual(MusicCapturePolicy.Configuration.music, .init(
            voiceProcessingEnabled: false,
            agcEnabled: false,
            bypassVoiceProcessing: true
        ))
        XCTAssertEqual(
            MusicCapturePolicy.Configuration.voiceWhileStereo,
            .init(
                voiceProcessingEnabled: false,
                agcEnabled: true,
                bypassVoiceProcessing: true
            )
        )
        XCTAssertEqual(
            MusicCapturePolicy.Configuration.voice.muteMode,
            .voiceProcessing
        )
        XCTAssertEqual(
            MusicCapturePolicy.Configuration.music.muteMode,
            .inputMixer
        )
    }

    func test_setDesiredMusic_whileMuted_keepsPendingUntilMarkApplied() {
        subject.setDesiredMusic(true, restorePlayout: true, isMuted: true)

        XCTAssertTrue(subject.isMusicCaptureEnabled)
        XCTAssertTrue(subject.hasPendingApply)
        XCTAssertTrue(subject.pendingRestorePlayout)
        XCTAssertEqual(subject.applied, .voice)

        subject.setDesiredMusic(true, restorePlayout: false, isMuted: true)
        XCTAssertTrue(subject.pendingRestorePlayout)

        subject.markApplied(stereoPreferred: false)
        XCTAssertEqual(subject.applied, .music)
        XCTAssertFalse(subject.hasPendingApply)
    }

    func test_markApplied_whenLeavingMusicWithStereo_isVoiceWhileStereo() {
        subject.setDesiredMusic(true, restorePlayout: false, isMuted: false)
        subject.markApplied(stereoPreferred: false)
        subject.setDesiredMusic(false, restorePlayout: false, isMuted: false)
        subject.markApplied(stereoPreferred: true)

        XCTAssertEqual(subject.applied, .voiceWhileStereo)
        XCTAssertFalse(subject.needsCaptureApply(desiredMusic: false))
        XCTAssertEqual(
            subject.appliedConfiguration,
            .voiceWhileStereo
        )
        XCTAssertTrue(
            subject.bypassVoiceProcessing(stereoPreferred: false)
        )
        XCTAssertTrue(
            subject.needsVoiceProcessingRestore(stereoPreferred: false)
        )
        XCTAssertFalse(
            subject.needsVoiceProcessingRestore(stereoPreferred: true)
        )
    }

    func test_needsVoiceProcessingRestore_neverMusicStereo_isFalse() {
        XCTAssertFalse(
            subject.needsVoiceProcessingRestore(stereoPreferred: false)
        )
        XCTAssertFalse(
            subject.needsVoiceProcessingRestore(stereoPreferred: true)
        )
    }
}
