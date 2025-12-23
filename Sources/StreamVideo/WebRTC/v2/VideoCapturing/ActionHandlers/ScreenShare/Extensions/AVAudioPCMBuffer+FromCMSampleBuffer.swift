//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
import Foundation

extension AVAudioPCMBuffer {

    /// Creates a PCM buffer from an audio CMSampleBuffer when possible.
    static func from(
        _ source: CMSampleBuffer
    ) -> AVAudioPCMBuffer? {
        // Extract format information so we can build a matching PCM buffer.
        guard
            let formatDescription = CMSampleBufferGetFormatDescription(source),
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(
                formatDescription
            )
        else {
            // Format description is required to interpret the sample buffer.
            log.error("2")
            return nil
        }

        // Only linear PCM can be copied into AVAudioPCMBuffer.
        guard asbd.pointee.mFormatID == kAudioFormatLinearPCM else {
            log.error("3")
            return nil
        }

        // Capture format flags to decide how to interpret sample data.
        let formatFlags = asbd.pointee.mFormatFlags
        // Float data can be used directly without scaling.
        let isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0
        // Signed integer data needs conversion and scaling.
        let isSignedInt = (formatFlags & kAudioFormatFlagIsSignedInteger) != 0
        // Endianness matters when bytes are not native order.
        let isBigEndian = (formatFlags & kAudioFormatFlagIsBigEndian) != 0
        // Interleaving determines channel layout in memory.
        let isInterleaved = (formatFlags
            & kAudioFormatFlagIsNonInterleaved
        ) == 0
        // Bit depth drives the common PCM format choice.
        let bitsPerChannel = Int(asbd.pointee.mBitsPerChannel)

        // Choose an AVAudioCommonFormat compatible with the sample format.
        let commonFormat: AVAudioCommonFormat
        if isFloat, bitsPerChannel == 32 {
            // 32-bit float is the standard ReplayKit float format.
            commonFormat = .pcmFormatFloat32
        } else if isSignedInt, bitsPerChannel == 16 {
            // 16-bit signed integers are common for PCM audio.
            commonFormat = .pcmFormatInt16
        } else {
            // Unsupported bit depth or type cannot be represented.
            log.error("4")
            return nil
        }

        // Build a concrete AVAudioFormat matching the CMSampleBuffer.
        guard
            let inputFormat = AVAudioFormat(
                commonFormat: commonFormat,
                sampleRate: asbd.pointee.mSampleRate,
                channels: asbd.pointee.mChannelsPerFrame,
                interleaved: isInterleaved
            )
        else {
            // Format construction failure prevents buffer allocation.
            log.error("4")
            return nil
        }

        // Determine how many frames are in the sample buffer.
        let frameCount = AVAudioFrameCount(
            CMSampleBufferGetNumSamples(source)
        )
        guard
            frameCount > 0,
            let pcmBuffer = AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: frameCount
            )
        else {
            // Frame count must be positive and buffer allocation must succeed.
            log.error("5")
            return nil
        }

        // Update the buffer length to match the number of frames.
        pcmBuffer.frameLength = frameCount

        // Bytes per frame are needed to calculate copy sizes.
        let bytesPerFrame = Int(asbd.pointee.mBytesPerFrame)
        guard bytesPerFrame > 0 else {
            log.error("6")
            return nil
        }

        // Get a mutable view over the destination AudioBufferList.
        let destinationList = UnsafeMutableAudioBufferListPointer(
            pcmBuffer.mutableAudioBufferList
        )
        // Total byte count to copy into each buffer.
        let bytesToCopy = Int(frameCount) * bytesPerFrame
        for index in 0..<destinationList.count {
            // Update each buffer's size to match the copy length.
            var destinationBuffer = destinationList[index]
            destinationBuffer.mDataByteSize = UInt32(bytesToCopy)
            destinationList[index] = destinationBuffer
        }

        // Copy PCM bytes from the CMSampleBuffer into the AudioBufferList.
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            source,
            at: 0,
            frameCount: Int32(frameCount),
            into: destinationList.unsafeMutablePointer
        )
        guard status == noErr else {
            // Report copy failures with the OSStatus.
            log.error("7:\(status)")
            return nil
        }

        // Convert big-endian samples to native endianness in place.
        if isBigEndian {
            let bufferList = UnsafeMutableAudioBufferListPointer(
                pcmBuffer.mutableAudioBufferList
            )
            for buffer in bufferList {
                // Skip empty buffers.
                guard let mData = buffer.mData else {
                    continue
                }
                if commonFormat == .pcmFormatInt16 {
                    // Count Int16 samples based on byte size.
                    let sampleCount = Int(buffer.mDataByteSize)
                        / MemoryLayout<Int16>.size
                    // Bind the memory to Int16 for swapping.
                    let intPtr = mData.assumingMemoryBound(to: Int16.self)
                    for index in 0..<sampleCount {
                        // Swap each sample from big endian to native.
                        intPtr[index] = Int16(bigEndian: intPtr[index])
                    }
                } else if commonFormat == .pcmFormatFloat32 {
                    // Float data uses UInt32 swapping on the bit pattern.
                    let sampleCount = Int(buffer.mDataByteSize)
                        / MemoryLayout<UInt32>.size
                    // Treat float samples as raw UInt32 for swapping.
                    let intPtr = mData.assumingMemoryBound(to: UInt32.self)
                    for index in 0..<sampleCount {
                        // Byte-swap each 32-bit float value.
                        intPtr[index] = intPtr[index].byteSwapped
                    }
                }
            }
        }

        // Return the filled PCM buffer ready for processing.
        return pcmBuffer
    }

    // No extra helpers.
}
