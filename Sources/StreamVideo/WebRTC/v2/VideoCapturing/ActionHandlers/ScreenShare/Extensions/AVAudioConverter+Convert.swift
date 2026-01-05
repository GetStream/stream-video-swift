//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
import Foundation

extension AVAudioConverter {

    /// Converts an audio buffer to the requested output format.
    func convert(
        from inputBuffer: AVAudioPCMBuffer,
        to outputFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        // Frame length is stored as an integer; convert to Double for math.
        let inputFrames = Double(inputBuffer.frameLength)
        // Ratio between output and input sample rates drives resampling.
        let ratio = outputFormat.sampleRate / inputBuffer.format.sampleRate
        // Compute how many frames the output buffer must hold.
        let outputFrameCapacity = AVAudioFrameCount(
            max(1, ceil(inputFrames * ratio))
        )

        // Allocate the output buffer in the requested format.
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            // Allocation failure leaves no buffer to write into.
            return nil
        }

        // Collect conversion errors from AVAudioConverter.
        var error: NSError?
        // Track whether we already provided the input buffer.
        nonisolated(unsafe) var didProvideData = false
        // Perform conversion with a synchronous input block.
        let status = self.convert(
            to: outputBuffer,
            error: &error
        ) { _, outStatus in
            // Provide input only once; then signal no more data.
            if didProvideData {
                outStatus.pointee = .noDataNow
                return nil
            }
            // Empty input means there is nothing to convert.
            guard inputBuffer.frameLength > 0 else {
                outStatus.pointee = .noDataNow
                return nil
            }
            // Mark the input as consumed so we stop supplying it.
            didProvideData = true
            // Tell the converter that we supplied data.
            outStatus.pointee = .haveData
            // Return the single input buffer to the converter.
            return inputBuffer
        }

        // Conversion errors are signaled by status and error.
        if status == .error {
            if let error {
                log.error(error, subsystems: .videoCapturer)
            }
            return nil
        }

        // Zero-length output indicates conversion produced no data.
        guard outputBuffer.frameLength > 0 else {
            return nil
        }

        // The output buffer now contains converted audio frames.
        return outputBuffer
    }
}
