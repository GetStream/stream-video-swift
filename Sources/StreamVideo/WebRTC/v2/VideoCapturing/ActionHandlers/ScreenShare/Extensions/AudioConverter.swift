//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
import Foundation

/// Converts audio buffers between formats while caching converter state.
final class AudioConverter {
    // Cached converter instance reused for matching format pairs.
    private var audioConverter: AVAudioConverter?
    // Cached input format used to validate converter reuse.
    private var audioConverterInputFormat: AVAudioFormat?
    // Cached output format used to validate converter reuse.
    private var audioConverterOutputFormat: AVAudioFormat?

    /// Resets cached converter state.
    func reset() {
        // Drop the converter so a new one can be created as needed.
        audioConverter = nil
        // Clear cached input format to force reconfiguration.
        audioConverterInputFormat = nil
        // Clear cached output format to force reconfiguration.
        audioConverterOutputFormat = nil
    }

    /// Converts the buffer when formats differ, returning the original
    /// buffer when compatible.
    func convertIfRequired(
        _ inputBuffer: AVAudioPCMBuffer,
        to outputFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        // When formats already match, no conversion is needed.
        if inputBuffer.format == outputFormat {
            return inputBuffer
        } else {
            // Ensure a converter exists for this specific format pair.
            ensureCorrectConverterExists(
                from: inputBuffer.format,
                to: outputFormat
            )
            // Use the cached converter to perform the conversion.
            return audioConverter?.convert(
                from: inputBuffer,
                to: outputFormat
            )
        }
    }

    // MARK: - Private Helpers

    private func ensureCorrectConverterExists(
        from inputFormat: AVAudioFormat,
        to outputFormat: AVAudioFormat
    ) {
        // Recreate the converter when formats differ or are missing.
        let needsNewConverter = audioConverter == nil
            || audioConverterInputFormat != inputFormat
            || audioConverterOutputFormat != outputFormat

        // If the converter matches the formats, reuse it as-is.
        guard needsNewConverter else {
            return
        }

        // Create a new converter for the requested format pair.
        audioConverter = AVAudioConverter(
            from: inputFormat,
            to: outputFormat
        )
        // Use the highest quality sample rate conversion.
        audioConverter?.sampleRateConverterQuality = AVAudioQuality.max
            .rawValue
        // Choose a high-quality algorithm for resampling.
        audioConverter?.sampleRateConverterAlgorithm =
            AVSampleRateConverterAlgorithm_Mastering
        // Cache the formats that the converter was built for.
        audioConverterInputFormat = inputFormat
        audioConverterOutputFormat = outputFormat
    }
}
