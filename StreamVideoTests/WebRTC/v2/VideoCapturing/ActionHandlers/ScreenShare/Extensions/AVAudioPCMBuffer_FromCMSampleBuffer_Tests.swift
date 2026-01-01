//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioPCMBuffer_FromCMSampleBuffer_Tests: XCTestCase,
    @unchecked Sendable {

    private var subject: AVAudioPCMBuffer!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_from_withFloatSampleBuffer_returnsPCMBuffer() {
        let samples: [Float] = [0.25, -0.25, 0.5, -0.5]
        let sampleBuffer = makeSampleBuffer(samples: samples)

        subject = AVAudioPCMBuffer.from(sampleBuffer)

        XCTAssertNotNil(subject)
        XCTAssertEqual(subject.frameLength, AVAudioFrameCount(samples.count))
        XCTAssertEqual(subject.format.sampleRate, 48000)
        XCTAssertEqual(subject.format.channelCount, 1)
        if let channel = subject.floatChannelData?.pointee {
            for (index, sample) in samples.enumerated() {
                XCTAssertEqual(channel[index], sample, accuracy: 0.000_1)
            }
        } else {
            XCTFail("Expected floatChannelData for float format.")
        }
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
