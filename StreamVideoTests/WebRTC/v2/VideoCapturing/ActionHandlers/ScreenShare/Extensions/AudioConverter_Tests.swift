//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AudioConverter_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AudioConverter!

    override func setUp() {
        super.setUp()
        subject = AudioConverter()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_convertIfRequired_withMatchingFormat_returnsInput() {
        let inputBuffer = makeFloatBuffer(samples: [0.1, 0.2])

        let outputBuffer = subject.convertIfRequired(
            inputBuffer,
            to: inputBuffer.format
        )

        XCTAssertTrue(outputBuffer === inputBuffer)
    }

    func test_convertIfRequired_withDifferentFormat_returnsConvertedBuffer() {
        let inputBuffer = makeFloatBuffer(samples: Array(repeating: 0.2, count: 4800))
        let outputFormat = makeFormat(sampleRate: 16000)

        let outputBuffer = subject.convertIfRequired(
            inputBuffer,
            to: outputFormat
        )

        XCTAssertNotNil(outputBuffer)
        XCTAssertTrue(outputBuffer?.frameLength ?? 0 > 0)
        XCTAssertTrue(outputBuffer?.format == outputFormat)
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
