//
//  AudioEngineLevelNodeAdapter.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 8/10/25.
//

import Accelerate
import Foundation
import AVFoundation

final class AudioEngineLevelNodeAdapter {

    private let publisher: (Float) -> Void
    private var inputTap: AVAudioMixerNode?

    init(publisher: @escaping (Float) -> Void) {
        self.publisher = publisher
    }

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
    }

    func uninstall(on bus: Int = 0) {
        if let mixer = inputTap {
            mixer.removeTap(onBus: 0)
            inputTap = nil
            publisher(0)
        }
    }

    // MARK: - Private Helpers

    private func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = vDSP_Length(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(channelData[0], 1, &rms, frameCount)

        let rmsDB  = 20 * log10(max(rms,  Float.ulpOfOne))
        let clampedRMS = max(-160.0, min(0.0, Float(rmsDB)))

        publisher(clampedRMS)
    }
}
