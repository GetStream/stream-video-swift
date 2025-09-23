//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreMedia
import Foundation

final class ScreenShareAudioDiagnostics {

    private struct AudioStats {
        var frames: AVAudioFrameCount
        var channels: UInt32
        var maxMagnitude: Double
        var rms: Double
        var sampleRate: Double
    }

    private let logInterval: UInt64 = 30
    private var frameIndex: UInt64 = 0
    private var consecutiveSilentFrames: UInt64 = 0

    func analyze(
        original originalBuffer: CMSampleBuffer,
        converted convertedBuffer: CMSampleBuffer
    ) {
        #if DEBUG
        guard
            let convertedStats = makeStats(from: convertedBuffer),
            let originalStats = makeStats(from: originalBuffer)
        else {
            return
        }

        _log(converted: convertedStats, original: originalStats)
        #endif
    }

    func analyze(sampleBuffer: CMSampleBuffer) {
        #if DEBUG
        guard let stats = makeStats(from: sampleBuffer) else {
            return
        }

        _log(converted: stats, original: nil)
        #endif
    }

    // MARK: - Private helpers

    private func _log(converted: AudioStats, original: AudioStats?) {
        frameIndex += 1

        if converted.maxMagnitude == 0 {
            consecutiveSilentFrames += 1
        } else {
            consecutiveSilentFrames = 0
        }

        let shouldLog: Bool = if converted.maxMagnitude == 0 {
            consecutiveSilentFrames % logInterval == 1
        } else {
            frameIndex % logInterval == 0
        }

        guard shouldLog else {
            return
        }

        let convertedMaxDb = amplitudeToDb(converted.maxMagnitude)
        let convertedRmsDb = amplitudeToDb(converted.rms)

        var message =
            "\(type(of: self)) converted frames:\(converted.frames) "
                + "channels:\(converted.channels) "
                + "sampleRate:\(converted.sampleRate) "
                + String(
                    format: "max:%.4f (%.1f dB) rms:%.4f (%.1f dB)",
                    converted.maxMagnitude,
                    convertedMaxDb,
                    converted.rms,
                    convertedRmsDb
                )

        if let original {
            let originalMaxDb = amplitudeToDb(original.maxMagnitude)
            let originalRmsDb = amplitudeToDb(original.rms)
            let rmsRatio = original.rms > 0 ? converted.rms / original.rms : 0
            message +=
                " | raw sampleRate:\(original.sampleRate) "
                + String(
                    format: "max:%.4f (%.1f dB) rms:%.4f (%.1f dB) ratio:%.3f",
                    original.maxMagnitude,
                    originalMaxDb,
                    original.rms,
                    originalRmsDb,
                    rmsRatio
                )
        }

        log.debug(
            message,
            subsystems: .videoCapturer
        )
    }

    private func makeStats(from sampleBuffer: CMSampleBuffer) -> AudioStats? {
        guard
            let floatBuffer = makeFloatBuffer(from: sampleBuffer),
            let channelData = floatBuffer.floatChannelData
        else {
            return nil
        }

        let frameLength = Int(floatBuffer.frameLength)
        guard frameLength > 0 else {
            return nil
        }

        let channelCount = Int(floatBuffer.format.channelCount)
        var maxMagnitude: Double = 0
        var sumSquares: Double = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                let sample = Double(samples[frame])
                let magnitude = abs(sample)
                if magnitude > maxMagnitude {
                    maxMagnitude = magnitude
                }
                sumSquares += sample * sample
            }
        }

        let totalSamples = frameLength * channelCount
        let rms = totalSamples > 0
            ? sqrt(sumSquares / Double(totalSamples))
            : 0

        return AudioStats(
            frames: floatBuffer.frameLength,
            channels: UInt32(channelCount),
            maxMagnitude: maxMagnitude,
            rms: rms,
            sampleRate: floatBuffer.format.sampleRate
        )
    }

    private func makeFloatBuffer(
        from sampleBuffer: CMSampleBuffer
    ) -> AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(
            sampleBuffer
        ) else {
            return nil
        }

        guard let streamDescriptionPointer =
            CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else {
            return nil
        }

        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard frameCount > 0 else {
            return nil
        }

        var streamDescription = streamDescriptionPointer.pointee
        guard let inputFormat = AVAudioFormat(
            streamDescription: &streamDescription
        ) else {
            return nil
        }

        let frames = AVAudioFrameCount(frameCount)
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFormat,
            frameCapacity: frames
        ) else {
            return nil
        }
        inputBuffer.frameLength = frames

        let copyStatus = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: Int32(frames),
            into: inputBuffer.mutableAudioBufferList
        )

        guard copyStatus == noErr else {
            return nil
        }

        let analysisFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: inputFormat.channelCount,
            interleaved: false
        )

        guard let analysisFormat else {
            return nil
        }

        let formatsMatch =
            inputFormat.commonFormat == analysisFormat.commonFormat &&
            inputFormat.channelCount == analysisFormat.channelCount &&
            inputFormat.sampleRate == analysisFormat.sampleRate &&
            inputFormat.isInterleaved == analysisFormat.isInterleaved

        if formatsMatch {
            return inputBuffer
        }

        guard let analysisBuffer = AVAudioPCMBuffer(
            pcmFormat: analysisFormat,
            frameCapacity: frames
        ) else {
            return nil
        }
        analysisBuffer.frameLength = frames

        guard let converter = AVAudioConverter(
            from: inputFormat,
            to: analysisFormat
        ) else {
            return nil
        }

        var conversionError: NSError?
        var hasSuppliedInput = false
        let status = converter.convert(
            to: analysisBuffer,
            error: &conversionError
        ) { _, statusPointer in
            guard hasSuppliedInput == false else {
                statusPointer.pointee = .noDataNow
                return nil
            }

            hasSuppliedInput = true
            statusPointer.pointee = .haveData
            return inputBuffer
        }

        guard conversionError == nil else {
            return nil
        }

        switch status {
        case .haveData, .inputRanDry, .endOfStream:
            return analysisBuffer
        case .error:
            return nil
        @unknown default:
            return nil
        }
    }

    private func amplitudeToDb(_ amplitude: Double) -> Double {
        guard amplitude > 0 else {
            return -Double.infinity
        }
        return 20 * log10(amplitude)
    }
}
