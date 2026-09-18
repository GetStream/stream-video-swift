//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AudioBitrateProfile_Tests: XCTestCase, @unchecked Sendable {

    func test_defaultBitrate_matchesVoiceAndMusicRates() {
        XCTAssertEqual(AudioBitrateProfile.voiceStandard.defaultBitrate, 64000)
        XCTAssertEqual(AudioBitrateProfile.voiceHighQuality.defaultBitrate, 128_000)
        XCTAssertEqual(AudioBitrateProfile.musicHighQuality.defaultBitrate, 128_000)
    }

    func test_sfuProfile_roundTripsKnownValues() {
        AudioBitrateProfile.allCases.forEach { profile in
            XCTAssertEqual(AudioBitrateProfile(profile.sfuProfile), profile)
        }
    }

    func test_initFromUnrecognizedSFUProfile_returnsNil() {
        XCTAssertNil(AudioBitrateProfile(.UNRECOGNIZED(99)))
    }

    func test_bitrateFor_prefersSFUMapping() {
        let options = PublishOptions.AudioPublishOptions(
            codec: .opus,
            bitrate: 64000,
            bitrateProfiles: [
                .voiceStandard: 48000,
                .musicHighQuality: 192_000
            ]
        )

        XCTAssertEqual(options.bitrate(for: .voiceStandard), 48000)
        XCTAssertEqual(options.bitrate(for: .musicHighQuality), 192_000)
        XCTAssertEqual(options.bitrate(for: .voiceHighQuality), 128_000)
    }

    func test_bitrateFor_voiceStandardFallsBackToOptionBitrate() {
        let options = PublishOptions.AudioPublishOptions(
            codec: .opus,
            bitrate: 64000
        )

        XCTAssertEqual(options.bitrate(for: .voiceStandard), 64000)
        XCTAssertEqual(options.bitrate(for: .musicHighQuality), 128_000)
    }
}
