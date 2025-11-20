//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Accelerate
import AVFoundation
import Combine
import Foundation

protocol AudioEngineNodeAdapting {

    var subject: CurrentValueSubject<Float, Never>? { get set }

    func installInputTap(
        on node: AVAudioNode,
        format: AVAudioFormat,
        bus: Int,
        bufferSize: UInt32
    )

    func uninstall(on bus: Int)
}

/// Observes an `AVAudioMixerNode` and publishes decibel readings for UI and
/// analytics consumers.
final class AudioEngineLevelNodeAdapter: AudioEngineNodeAdapting {

    enum Constant {
        // The down limit of audio pipeline in DB that is considered silence.
        static let silenceDB: Float = -160
    }

    var subject: CurrentValueSubject<Float, Never>?

    private var inputTap: AVAudioMixerNode?

    /// Installs a tap on the supplied audio node to monitor input levels.
    /// - Parameters:
    ///   - node: The node to observe; must be an `AVAudioMixerNode`.
    ///   - format: Audio format expected by the tap.
    ///   - bus: Output bus to observe.
    ///   - bufferSize: Tap buffer size.
    func installInputTap(
        on node: AVAudioNode,
        format: AVAudioFormat,
        bus: Int = 0,
        bufferSize: UInt32 = 1024
    ) {
        guard let mixer = node as? AVAudioMixerNode, inputTap == nil else { return }

        mixer.installTap(
            onBus: bus,
            bufferSize: bufferSize,
            format: format
        ) { [weak self] buffer, _ in
            self?.processInputBuffer(buffer)
        }

        inputTap = mixer
        log.debug("Input node installed", subsystems: .audioRecording)
    }

    /// Removes the tap and resets observed audio levels.
    /// - Parameter bus: Bus to remove the tap from, defaults to `0`.
    func uninstall(on bus: Int = 0) {
        if let mixer = inputTap, mixer.engine != nil {
            mixer.removeTap(onBus: 0)
        }
        subject?.send(Constant.silenceDB)
        inputTap = nil
        log.debug("Input node uninstalled", subsystems: .audioRecording)
    }

    // MARK: - Private Helpers

    /// Processes the PCM buffer produced by the tap and computes a clamped RMS
    /// value which is forwarded to the publisher.
    private func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        // Safely unwrap the `subject` (used to publish updates) and the
        // `floatChannelData` (pointer to the interleaved or non-interleaved
        // channel samples in memory). If either is missing, exit early since
        // processing cannot continue.
        guard
            let subject,
            let channelData = buffer.floatChannelData
        else { return }

        // Obtain the total number of frames in the buffer as a vDSP-compatible
        // length type (`vDSP_Length`). This represents how many samples exist
        // per channel in the current audio buffer.
        let frameCount = vDSP_Length(buffer.frameLength)

        // Declare a variable to store the computed RMS (root-mean-square)
        // amplitude value for the buffer. It will represent the signal's
        // average power in linear scale (not decibels yet).
        var rms: Float = 0

        // Use Apple's Accelerate framework to efficiently compute the RMS
        // (root mean square) of the float samples in the first channel.
        // - Parameters:
        //   - channelData[0]: Pointer to the first channel’s samples.
        //   - 1: Stride between consecutive elements (every sample).
        //   - &rms: Output variable to store the computed RMS.
        //   - frameCount: Number of samples to process.
        vDSP_rmsqv(channelData[0], 1, &rms, frameCount)

        // Convert the linear RMS value to decibels using the formula
        // 20 * log10(rms). To avoid a log of zero (which is undefined),
        // use `max(rms, Float.ulpOfOne)` to ensure a minimal positive value.
        let rmsDB = 20 * log10(max(rms, Float.ulpOfOne))

        // Clamp the computed decibel value to a reasonable audio level range
        // between -160 dB (silence) and 0 dB (maximum). This prevents extreme
        // or invalid values that may occur due to noise or computation errors.
        let clampedRMS = max(-160.0, min(0.0, Float(rmsDB)))

        // Publish the clamped decibel value to the CurrentValueSubject so that
        // subscribers (e.g., UI level meters or analytics systems) receive the
        // updated level reading.
        subject.send(clampedRMS)
    }
}
