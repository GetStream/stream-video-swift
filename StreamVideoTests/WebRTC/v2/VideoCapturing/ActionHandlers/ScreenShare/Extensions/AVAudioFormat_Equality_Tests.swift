//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioFormat_Equality_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AVAudioFormat!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_equatable_withMatchingValues_returnsTrue() {
        subject = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let other = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        XCTAssertTrue(subject == other)
    }

    func test_equatable_withDifferentSampleRate_returnsFalse() {
        subject = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let other = makeFormat(
            sampleRate: 44100,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        XCTAssertFalse(subject == other)
    }

    func test_equatable_withDifferentChannels_returnsFalse() {
        subject = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let other = makeFormat(
            sampleRate: 48000,
            channels: 2,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        XCTAssertFalse(subject == other)
    }

    func test_equatable_withDifferentCommonFormat_returnsFalse() {
        subject = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let other = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatInt16,
            interleaved: false
        )

        XCTAssertFalse(subject == other)
    }

    func test_equatable_withDifferentInterleaving_returnsFalse() {
        subject = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let other = makeFormat(
            sampleRate: 48000,
            channels: 1,
            commonFormat: .pcmFormatFloat32,
            interleaved: true
        )

        XCTAssertNotEqual(subject, other)
    }

    // MARK: - Helpers

    private func makeFormat(
        sampleRate: Double,
        channels: AVAudioChannelCount,
        commonFormat: AVAudioCommonFormat,
        interleaved: Bool
    ) -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: commonFormat,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: interleaved
        )!
    }
}
