//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioPCMBuffer_Info_Tests: XCTestCase, @unchecked Sendable {

    private var subject: AVAudioPCMBuffer!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_rmsAndPeak_withFloatSamples_returnsExpectedValues() {
        subject = makeFloatBuffer(samples: [0, 0.5, -0.5, 1])

        let info = subject.rmsAndPeak

        XCTAssertEqual(info.peak, 1, accuracy: 0.001)
        XCTAssertEqual(info.rms, 0.612_372, accuracy: 0.001)
        XCTAssertFalse(info.isSilent)
    }

    func test_rmsAndPeak_withInt16Samples_returnsExpectedValues() {
        subject = makeInt16Buffer(samples: [0, Int16.max])

        let info = subject.rmsAndPeak

        XCTAssertEqual(info.peak, 1, accuracy: 0.001)
        XCTAssertEqual(info.rms, 0.707_106, accuracy: 0.001)
        XCTAssertFalse(info.isSilent)
    }

    func test_rmsAndPeak_withZeroFrames_returnsEmpty() {
        subject = makeFloatBuffer(samples: [0])
        subject.frameLength = 0

        let info = subject.rmsAndPeak

        XCTAssertEqual(info, .empty)
    }

    func test_rmsAndPeakInfo_withLowRms_marksSilent() {
        let info = AVAudioPCMBuffer.RMSAndPeakInfo(rms: 0.000_1, peak: 0)

        XCTAssertTrue(info.isSilent)
    }

    func test_rmsAndPeakInfo_withHigherRms_marksNotSilent() {
        let info = AVAudioPCMBuffer.RMSAndPeakInfo(rms: 0.1, peak: 0)

        XCTAssertFalse(info.isSilent)
    }

    func test_description_includesFormatDetails() {
        subject = makeFloatBuffer(samples: [0.1, -0.1])

        let description = subject.description

        XCTAssertTrue(description.contains("channelCount:1"))
        XCTAssertTrue(description.contains("commonFormat:"))
        XCTAssertTrue(description.contains("isInterleaved:"))
    }

    // MARK: - Helpers

    private func makeFloatBuffer(samples: [Float]) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
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

    private func makeInt16Buffer(samples: [Int16]) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        )!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.int16ChannelData?.pointee {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }
        return buffer
    }
}
