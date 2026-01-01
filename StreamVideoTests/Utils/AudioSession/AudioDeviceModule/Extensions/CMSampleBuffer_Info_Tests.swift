//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
@testable import StreamVideo
import XCTest

final class CMSampleBuffer_Info_Tests: XCTestCase, @unchecked Sendable {

    private var subject: CMSampleBuffer!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_rmsAndPeak_withFloatSamples_returnsExpectedValues() {
        subject = makeSampleBuffer(samples: [0, 0.5, -0.5, 1])

        let info = subject.rmsAndPeak

        XCTAssertEqual(info.peak, 1, accuracy: 0.001)
        XCTAssertEqual(info.rms, 0.612_372, accuracy: 0.001)
        XCTAssertFalse(info.isSilent)
    }

    func test_format_withValidBuffer_returnsStreamDescription() {
        subject = makeSampleBuffer(samples: [0.25, -0.25])

        let format = subject.format

        XCTAssertEqual(format?.mFormatID, kAudioFormatLinearPCM)
        XCTAssertEqual(format?.mBitsPerChannel, 32)
        XCTAssertEqual(format?.mChannelsPerFrame, 1)
    }

    func test_description_includesFormatDetails() {
        subject = makeSampleBuffer(samples: [0.25, -0.25])

        let description = subject.description

        XCTAssertTrue(description.contains("channelCount:1"))
        XCTAssertTrue(description.contains("format:"))
    }

    // MARK: - Helpers

    private func makeSampleBuffer(samples: [Float]) -> CMSampleBuffer {
        var streamDescription = AudioStreamBasicDescription(
            mSampleRate: 48000,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(MemoryLayout<Float>.size),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(MemoryLayout<Float>.size),
            mChannelsPerFrame: 1,
            mBitsPerChannel: 32,
            mReserved: 0
        )

        var formatDescription: CMAudioFormatDescription?
        let formatStatus = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &streamDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        XCTAssertEqual(formatStatus, noErr)
        let format = formatDescription!

        let dataSize = samples.count * MemoryLayout<Float>.size
        var blockBuffer: CMBlockBuffer?
        let blockStatus = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: dataSize,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataSize,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        XCTAssertEqual(blockStatus, noErr)
        let block = blockBuffer!

        samples.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            let replaceStatus = CMBlockBufferReplaceDataBytes(
                with: baseAddress,
                blockBuffer: block,
                offsetIntoDestination: 0,
                dataLength: dataSize
            )
            XCTAssertEqual(replaceStatus, noErr)
        }

        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: block,
            formatDescription: format,
            sampleCount: samples.count,
            presentationTimeStamp: .zero,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        XCTAssertEqual(sampleStatus, noErr)
        return sampleBuffer!
    }
}
