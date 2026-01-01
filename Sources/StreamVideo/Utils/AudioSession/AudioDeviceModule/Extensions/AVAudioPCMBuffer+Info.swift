//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Accelerate
import AudioToolbox
import AVFoundation
import Foundation

extension AVAudioPCMBuffer {
    /// RMS and peak levels computed from a PCM buffer.
    ///
    /// Values are stored in linear amplitude and converted to decibels on
    /// demand. This keeps computation lightweight while exposing log-friendly
    /// values when needed.
    struct RMSAndPeakInfo: Equatable, CustomStringConvertible {
        /// Root-mean-square amplitude in linear scale.
        var rms: Float
        /// Peak amplitude in linear scale.
        var peak: Float

        /// RMS converted to decibels with a floor to avoid log(0).
        var rmsDb: Float { 20 * log10(max(rms, 1.0e-7)) }
        /// Peak converted to decibels with a floor to avoid log(0).
        var peakDb: Float { 20 * log10(max(peak, 1.0e-7)) }
        /// A conservative silence threshold in decibels.
        var isSilent: Bool { rmsDb <= -60 }

        var description: String {
            "{ rms:\(rms), peak:\(peak), rmsDb:\(rmsDb), " +
                "peakDb:\(peakDb), isSilent:\(isSilent) }"
        }

        static let empty = Self(rms: 0, peak: 0)
    }

    /// RMS and peak information computed from the buffer samples.
    var rmsAndPeak: RMSAndPeakInfo {
        // Convert to Int once to avoid repeated casting.
        let frameLength = Int(self.frameLength)
        // Empty buffers cannot yield meaningful audio statistics.
        guard frameLength > 0 else {
            return .empty
        }

        // Only linear PCM formats are supported for raw sample access.
        let streamDescription = format.streamDescription
        guard
            streamDescription.pointee.mFormatID == kAudioFormatLinearPCM
        else {
            return .empty
        }

        // Extract format flags that describe sample layout and encoding.
        let formatFlags = streamDescription.pointee.mFormatFlags
        // Endianness matters for integer data conversion.
        let isBigEndian = (formatFlags & kAudioFormatFlagIsBigEndian) != 0
        // Float indicates samples are already normalized floats.
        let isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0
        // Signed integer indicates PCM int samples need scaling.
        let isSignedInt = (formatFlags & kAudioFormatFlagIsSignedInteger) != 0
        // Bit depth drives bytes-per-sample and conversion strategy.
        let bitsPerChannel = Int(streamDescription.pointee.mBitsPerChannel)
        // Bytes per sample is used to compute sample counts.
        let bytesPerSample = bitsPerChannel / 8
        guard bytesPerSample > 0 else {
            return .empty
        }

        // Aggregate RMS and peak across channels by keeping maxima.
        var rms: Float = 0
        var peak: Float = 0
        // Use the underlying buffer list to access each channel buffer.
        let bufferList = UnsafeMutableAudioBufferListPointer(
            self.mutableAudioBufferList
        )

        for buffer in bufferList {
            // Skip buffers with no data.
            guard let mData = buffer.mData else {
                continue
            }

            if isFloat && bitsPerChannel == 32 {
                // Sample count is derived from byte size and sample width.
                let sampleCount = Int(buffer.mDataByteSize) / bytesPerSample
                // No samples means no statistics for this channel.
                guard sampleCount > 0 else {
                    continue
                }
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
                // Sample count is derived from byte size and sample width.
                let sampleCount = Int(buffer.mDataByteSize) / bytesPerSample
                guard sampleCount > 0 else {
                    continue
                }
                // Interpret raw data as signed 16-bit PCM.
                let intPtr = mData.assumingMemoryBound(to: Int16.self)
                // Convert to float so vDSP can operate efficiently.
                var floatData = [Float](repeating: 0, count: sampleCount)
                if isBigEndian {
                    // Swap endianness to native before conversion.
                    var swapped = [Int16](repeating: 0, count: sampleCount)
                    for index in 0..<sampleCount {
                        swapped[index] = Int16(bigEndian: intPtr[index])
                    }
                    // Convert int16 samples to float.
                    vDSP_vflt16(
                        swapped,
                        1,
                        &floatData,
                        1,
                        vDSP_Length(sampleCount)
                    )
                } else {
                    // Convert int16 samples to float.
                    vDSP_vflt16(
                        intPtr,
                        1,
                        &floatData,
                        1,
                        vDSP_Length(sampleCount)
                    )
                }
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
