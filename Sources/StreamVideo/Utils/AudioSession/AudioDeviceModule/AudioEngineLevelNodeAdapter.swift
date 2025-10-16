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

    var subject: CurrentValueSubject<Float, Never>?

//    private let publisher: (Float) -> Void
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
        subject?.send(-160)
        inputTap = nil
        log.debug("Input node uninstalled", subsystems: .audioRecording)
    }

    // MARK: - Private Helpers

    /// Processes the PCM buffer produced by the tap and computes a clamped RMS
    /// value which is forwarded to the publisher.
    private func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        guard
            let subject,
            let channelData = buffer.floatChannelData
        else { return }

        let frameCount = vDSP_Length(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(channelData[0], 1, &rms, frameCount)

        let rmsDB = 20 * log10(max(rms, Float.ulpOfOne))
        let clampedRMS = max(-160.0, min(0.0, Float(rmsDB)))

        subject.send(clampedRMS)
    }
}
