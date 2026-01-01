//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioConverter_Convert_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AVAudioConverter!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_convert_withValidInput_returnsOutputBuffer() {
        let inputBuffer = makeFloatBuffer(samples: Array(repeating: 0.2, count: 4800))
        let outputFormat = makeFormat(sampleRate: 16000)
        subject = AVAudioConverter(from: inputBuffer.format, to: outputFormat)

        let outputBuffer = subject.convert(
            from: inputBuffer,
            to: outputFormat
        )

        XCTAssertNotNil(outputBuffer)
        XCTAssertTrue(outputBuffer?.frameLength ?? 0 > 0)
        XCTAssertTrue(outputBuffer?.format == outputFormat)
    }

    func test_convert_withEmptyInput_returnsNil() {
        let inputBuffer = makeFloatBuffer(samples: [0])
        inputBuffer.frameLength = 0
        let outputFormat = makeFormat(sampleRate: 16000)
        subject = AVAudioConverter(from: inputBuffer.format, to: outputFormat)

        let outputBuffer = subject.convert(
            from: inputBuffer,
            to: outputFormat
        )

        XCTAssertNil(outputBuffer)
    }

    // MARK: - Helpers

    private func makeFloatBuffer(samples: [Float]) -> AVAudioPCMBuffer {
        let format = makeFormat(sampleRate: 48000)
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        )!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?.pointee {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }
        return buffer
    }

    private func makeFormat(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
    }
}
