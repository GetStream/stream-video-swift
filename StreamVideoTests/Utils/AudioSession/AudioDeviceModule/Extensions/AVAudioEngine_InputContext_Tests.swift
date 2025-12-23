//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioEngine_InputContext_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AVAudioEngine.InputContext!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_equatable_withMatchingValues_returnsTrue() {
        let engine = AVAudioEngine()
        let source = AVAudioPlayerNode()
        let destination = AVAudioMixerNode()
        let format = makeFormat(sampleRate: 48000)

        subject = .init(
            engine: engine,
            source: source,
            destination: destination,
            format: format
        )
        let other = AVAudioEngine.InputContext(
            engine: engine,
            source: source,
            destination: destination,
            format: format
        )

        XCTAssertEqual(subject, other)
    }

    func test_equatable_withDifferentEngine_returnsFalse() {
        let engine = AVAudioEngine()
        let destination = AVAudioMixerNode()
        let format = makeFormat(sampleRate: 48000)

        subject = .init(
            engine: engine,
            source: nil,
            destination: destination,
            format: format
        )
        let other = AVAudioEngine.InputContext(
            engine: AVAudioEngine(),
            source: nil,
            destination: destination,
            format: format
        )

        XCTAssertNotEqual(subject, other)
    }

    func test_equatable_withDifferentFormat_returnsFalse() {
        let engine = AVAudioEngine()
        let destination = AVAudioMixerNode()

        subject = .init(
            engine: engine,
            source: nil,
            destination: destination,
            format: makeFormat(sampleRate: 48000)
        )
        let other = AVAudioEngine.InputContext(
            engine: engine,
            source: nil,
            destination: destination,
            format: makeFormat(sampleRate: 44100)
        )

        XCTAssertNotEqual(subject, other)
    }

    // MARK: - Helpers

    private func makeFormat(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
    }
}
