//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
import CoreMedia
import Foundation

final class ScreenShareAudioConverter {

    private static let targetSampleRate: Double = 48000
    private static let targetSampleRateInt: Int = 48000

    enum ConversionResult {
        case success(CMSampleBuffer)
        case empty
        case noData(
            AudioStreamBasicDescription,
            AVAudioConverterOutputStatus,
            AVAudioFrameCount
        )
        case failure(
            file: StaticString = #fileID,
            function: StaticString = #function,
            line: UInt = #line
        )
    }

    private var converter: AVAudioConverter?
    private var inputFormat: AVAudioFormat?
    private var outputFormat: AVAudioFormat?
    private var outputFormatDescription: CMAudioFormatDescription?

    func convert(_ sampleBuffer: CMSampleBuffer) -> ConversionResult {
        guard let formatDescription = CMSampleBufferGetFormatDescription(
            sampleBuffer
        ) else {
            return .failure()
        }

        guard let streamDescriptionPointer =
            CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else {
            return .failure()
        }

        let streamDescription = streamDescriptionPointer.pointee

        guard streamDescription.mFormatID == kAudioFormatLinearPCM else {
            return .failure()
        }

        if Self.isTargetFormat(streamDescription) {
            return .success(sampleBuffer)
        }

        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard sampleCount > 0 else {
            return .empty
        }

        guard
            streamDescription.mChannelsPerFrame > 0,
            streamDescription.mSampleRate > 0
        else {
            return .failure()
        }

        guard let converter = prepareConverterIfNeeded(
            with: streamDescription
        ) else {
            return .failure()
        }

        guard let inputPCMBuffer = Self.makePCMBuffer(
            from: sampleBuffer,
            format: converter.inputFormat
        ) else {
            return .failure()
        }

        let outputCapacity = Self.outputFrameCapacity(
            forInputFrames: inputPCMBuffer.frameLength,
            inputSampleRate: converter.inputFormat.sampleRate,
            outputSampleRate: converter.outputFormat.sampleRate
        )

        guard let outputPCMBuffer = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: outputCapacity
        ) else {
            return .failure()
        }

        outputPCMBuffer.frameLength = outputCapacity

        var conversionError: NSError?
        var hasSuppliedInput = false
        let conversionStatus = converter.convert(
            to: outputPCMBuffer,
            error: &conversionError
        ) { _, outStatus in
            guard hasSuppliedInput == false else {
                outStatus.pointee = .noDataNow
                return nil
            }

            hasSuppliedInput = true
            outStatus.pointee = .haveData
            return inputPCMBuffer
        }

        guard conversionError == nil else {
            return .failure()
        }

        guard outputPCMBuffer.frameLength > 0 else {
            return .noData(
                streamDescription,
                conversionStatus,
                inputPCMBuffer.frameLength
            )
        }

        switch conversionStatus {
        case .haveData, .inputRanDry, .endOfStream:
            break
        case .error:
            return .failure()
        @unknown default:
            return .failure()
        }

        return makeSampleBuffer(
            from: outputPCMBuffer,
            originalSampleBuffer: sampleBuffer
        ).map(ConversionResult.success) ?? .failure()
    }

    private func prepareConverterIfNeeded(
        with streamDescription: AudioStreamBasicDescription
    ) -> AVAudioConverter? {
        var mutableStreamDescription = streamDescription
        guard let newInputFormat = AVAudioFormat(
            streamDescription: &mutableStreamDescription
        ) else {
            return nil
        }

        if let existingFormat = inputFormat,
           existingFormat.isEquivalent(to: newInputFormat) {
            return converter
        }

        guard let newOutputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.targetSampleRate,
            channels: newInputFormat.channelCount,
            interleaved: true
        ) else {
            return nil
        }

        guard let newConverter = AVAudioConverter(
            from: newInputFormat,
            to: newOutputFormat
        ) else {
            return nil
        }

        var outputStreamDescription = newOutputFormat.streamDescription.pointee
        var formatDescription: CMAudioFormatDescription?
        let status = withUnsafePointer(
            to: &outputStreamDescription
        ) { description in
            CMAudioFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                asbd: description,
                layoutSize: 0,
                layout: nil,
                magicCookieSize: 0,
                magicCookie: nil,
                extensions: nil,
                formatDescriptionOut: &formatDescription
            )
        }

        guard status == noErr, let formatDescription else {
            return nil
        }

        converter = newConverter
        inputFormat = newInputFormat
        outputFormat = newOutputFormat
        outputFormatDescription = formatDescription

        return newConverter
    }

    private func makeSampleBuffer(
        from pcmBuffer: AVAudioPCMBuffer,
        originalSampleBuffer: CMSampleBuffer
    ) -> CMSampleBuffer? {
        guard let outputFormatDescription else {
            return nil
        }

        let audioBufferListPointer = pcmBuffer.audioBufferList
        let frames = Int(pcmBuffer.frameLength)
        guard frames > 0 else {
            return nil
        }

        let formatPointer = pcmBuffer.format.streamDescription
        let bytesPerFrame = Int(formatPointer.pointee.mBytesPerFrame)
        let dataByteSize = frames * bytesPerFrame

        let audioBufferList = audioBufferListPointer.pointee
        guard audioBufferList.mNumberBuffers > 0 else {
            return nil
        }

        let audioBuffer = audioBufferList.mBuffers
        guard let sourcePointer = audioBuffer.mData else {
            return nil
        }

        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: dataByteSize,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataByteSize,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard status == kCMBlockBufferNoErr, let blockBuffer else {
            return nil
        }

        let bytePointer = sourcePointer.assumingMemoryBound(to: UInt8.self)
        status = CMBlockBufferReplaceDataBytes(
            with: bytePointer,
            blockBuffer: blockBuffer,
            offsetIntoDestination: 0,
            dataLength: dataByteSize
        )

        guard status == kCMBlockBufferNoErr else {
            return nil
        }

        let sampleCount = CMItemCount(frames)
        let originalDuration = CMSampleBufferGetDuration(originalSampleBuffer)
        let duration: CMTime = if originalDuration.isNumeric {
            originalDuration
        } else {
            CMTime(
                value: CMTimeValue(frames),
                timescale: CMTimeScale(Self.targetSampleRateInt)
            )
        }

        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(
            originalSampleBuffer
        )
        var timing = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: .invalid
        )

        var newSampleBuffer: CMSampleBuffer?
        status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: outputFormatDescription,
            sampleCount: sampleCount,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &newSampleBuffer
        )

        guard status == noErr else {
            return nil
        }

        return newSampleBuffer
    }

    private static func makePCMBuffer(
        from sampleBuffer: CMSampleBuffer,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard sampleCount > 0 else {
            return nil
        }

        let frameCount = AVAudioFrameCount(sampleCount)
        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            return nil
        }

        pcmBuffer.frameLength = frameCount
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: Int32(frameCount),
            into: pcmBuffer.mutableAudioBufferList
        )

        guard status == noErr else {
            return nil
        }

        return pcmBuffer
    }

    private static func isTargetFormat(
        _ streamDescription: AudioStreamBasicDescription
    ) -> Bool {
        guard streamDescription.mFormatID == kAudioFormatLinearPCM else {
            return false
        }

        let flags = streamDescription.mFormatFlags
        let requiredFlags = kAudioFormatFlagIsSignedInteger |
            kAudioFormatFlagIsPacked
        let prohibitedFlags = kAudioFormatFlagIsFloat |
            kAudioFormatFlagIsNonInterleaved |
            kAudioFormatFlagIsBigEndian
        let sampleRateMatches = abs(streamDescription.mSampleRate - targetSampleRate) < 1

        return (flags & requiredFlags) == requiredFlags &&
            (flags & prohibitedFlags) == 0 &&
            streamDescription.mBitsPerChannel == 16 &&
            sampleRateMatches
    }
}

private extension AVAudioFormat {
    func isEquivalent(to other: AVAudioFormat) -> Bool {
        sampleRate == other.sampleRate &&
            channelCount == other.channelCount &&
            commonFormat == other.commonFormat &&
            isInterleaved == other.isInterleaved
    }
}

private extension ScreenShareAudioConverter {
    static func outputFrameCapacity(
        forInputFrames inputFrames: AVAudioFrameCount,
        inputSampleRate: Double,
        outputSampleRate: Double
    ) -> AVAudioFrameCount {
        guard inputSampleRate > 0 else {
            return max(1, inputFrames)
        }

        let ratio = outputSampleRate / inputSampleRate
        let estimatedFrames = Double(inputFrames) * ratio
        let capacity = max(1, Int(ceil(estimatedFrames)))
        return AVAudioFrameCount(capacity)
    }
}
