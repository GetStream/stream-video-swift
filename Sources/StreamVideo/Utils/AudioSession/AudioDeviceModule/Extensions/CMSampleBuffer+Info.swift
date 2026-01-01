//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Accelerate
import AudioToolbox
import AVFoundation

extension CMSampleBuffer {
    /// RMS and peak levels computed from a sample buffer.
    ///
    /// Values are stored in linear amplitude and converted to decibels on
    /// demand to keep per-sample work minimal.
    struct RMSAndPeakInfo: Equatable, CustomStringConvertible {
        /// Root-mean-square amplitude in linear scale.
        var rms: Float
        /// Peak amplitude in linear scale.
        var peak: Float

        /// A conservative silence threshold in decibels.
        var isSilent: Bool { rmsDb <= -60 }
        /// RMS converted to decibels with a floor to avoid log(0).
        var rmsDb: Float { 20 * log10(max(rms, 1.0e-7)) }
        /// Peak converted to decibels with a floor to avoid log(0).
        var peakDb: Float { 20 * log10(max(peak, 1.0e-7)) }

        var description: String {
            "{ rms:\(rms), peak:\(peak), rmsDb:\(rmsDb), " +
                "peakDb:\(peakDb), isSilent:\(isSilent) }"
        }

        static let empty = Self(rms: 0, peak: 0)
    }

    /// The audio stream format, if available.
    var format: AudioStreamBasicDescription? {
        // Validate buffer state before extracting the format description.
        guard
            CMSampleBufferIsValid(self),
            CMSampleBufferDataIsReady(self),
            let formatDesc = CMSampleBufferGetFormatDescription(self),
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(
                formatDesc
            )
        else {
            return nil
        }
        return asbd.pointee
    }

    /// RMS and peak information computed from the audio samples.
    var rmsAndPeak: RMSAndPeakInfo {
        // We only support linear PCM for raw sample inspection.
        guard
            let asbd = format,
            asbd.mFormatID == kAudioFormatLinearPCM
        else {
            return .empty
        }

        // Bit depth and flags drive conversion strategy.
        let bitsPerChannel = Int(asbd.mBitsPerChannel)
        // Float samples can be processed directly.
        let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        // Int samples need conversion and scaling.
        let isSignedInt = (asbd.mFormatFlags
            & kAudioFormatFlagIsSignedInteger
        ) != 0
        // Bytes per sample is used to compute sample counts.
        let bytesPerSample = bitsPerChannel / 8
        guard bytesPerSample > 0 else { return .empty }

        // First call obtains the required AudioBufferList size.
        var bufferListSizeNeeded = 0
        var status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: &bufferListSizeNeeded,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: nil
        )
        guard status == noErr else { return .empty }

        // Allocate a buffer list with correct alignment for AudioBufferList.
        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: bufferListSizeNeeded,
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { rawPointer.deallocate() }

        // Bind the raw memory to AudioBufferList for Core Media APIs.
        let audioBufferListPointer = rawPointer.bindMemory(
            to: AudioBufferList.self,
            capacity: 1
        )

        // Second call fills the buffer list and retains the block buffer.
        var blockBuffer: CMBlockBuffer?
        status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferListPointer,
            bufferListSize: bufferListSizeNeeded,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr else { return .empty }

        // Iterate each AudioBuffer in the list.
        let bufferList = UnsafeMutableAudioBufferListPointer(
            audioBufferListPointer
        )
        // Aggregate RMS and peak across channels by keeping maxima.
        var rms: Float = 0
        var peak: Float = 0

        for buffer in bufferList {
            // Skip buffers with no data.
            guard let mData = buffer.mData else { continue }
            // Sample count is derived from bytes and sample width.
            let sampleCount = Int(buffer.mDataByteSize) / bytesPerSample
            guard sampleCount > 0 else { continue }

            if isFloat && bitsPerChannel == 32 {
                // Treat memory as float samples for vDSP routines.
                let floatPtr = mData.assumingMemoryBound(to: Float.self)
                var chRms: Float = 0
                var chPeak: Float = 0
                // RMS over the channel samples.
                vDSP_rmsqv(floatPtr, 1, &chRms, vDSP_Length(sampleCount))
                // Peak magnitude over the channel samples.
                vDSP_maxmgv(floatPtr, 1, &chPeak, vDSP_Length(sampleCount))
                // Keep the max across channels for a conservative summary.
                rms = max(rms, chRms)
                peak = max(peak, chPeak)
            } else if isSignedInt && bitsPerChannel == 16 {
                // Interpret raw data as signed 16-bit PCM.
                let intPtr = mData.assumingMemoryBound(to: Int16.self)
                // Convert to float so vDSP can operate efficiently.
                var floatData = [Float](repeating: 0, count: sampleCount)
                // Convert int16 samples to float.
                vDSP_vflt16(intPtr, 1, &floatData, 1, vDSP_Length(sampleCount))
                // Normalize to [-1, 1] using Int16 max value.
                var scale: Float = 1.0 / Float(Int16.max)
                vDSP_vsmul(
                    floatData,
                    1,
                    &scale,
                    &floatData,
                    1,
                    vDSP_Length(sampleCount)
                )
                var chRms: Float = 0
                var chPeak: Float = 0
                // RMS over normalized samples.
                vDSP_rmsqv(floatData, 1, &chRms, vDSP_Length(sampleCount))
                // Peak magnitude over normalized samples.
                vDSP_maxmgv(floatData, 1, &chPeak, vDSP_Length(sampleCount))
                // Keep the max across channels for a conservative summary.
                rms = max(rms, chRms)
                peak = max(peak, chPeak)
            } else {
                // Unsupported formats return an empty summary.
                return .empty
            }
        }

        // Return the aggregate RMS and peak values.
        return .init(rms: rms, peak: peak)
    }
}
