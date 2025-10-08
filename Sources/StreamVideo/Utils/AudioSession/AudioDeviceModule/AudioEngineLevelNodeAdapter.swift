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
    private var isInstalled = false

    init(publisher: @escaping (Float) -> Void) {
        self.publisher = publisher
    }

    func install(
        on audioEngine: AVAudioEngine,
        bufferSize: UInt32 = 1024
    ) {
        guard !isInstalled else {
            log.warning(
                "AudioEngineLevelNode is already installed. Cannot be installed again.",
                subsystems: .audioSession
            )
            return
        }

        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine
            .mainMixerNode
            .installTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: format
            ) { [weak self] buffer, _ in self?.didReceiveBuffer(buffer) }

        isInstalled = true
    }

    func uninstall(on audioEngine: AVAudioEngine) {
        guard isInstalled else {
            return
        }
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        publisher(0)
        isInstalled = false
    }

    // MARK: - Private Helpers

    private func didReceiveBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = vDSP_Length(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(channelData[0], 1, &rms, frameCount)

        let rmsDB  = 20 * log10(max(rms,  Float.ulpOfOne))
        let clampedRMS = max(-160.0, min(0.0, Float(rmsDB)))

        publisher(clampedRMS)
    }
}
