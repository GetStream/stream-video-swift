//
//  DemoVoiceProcessor.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import WebRTC

final class DemoVoiceProcessor: NSObject, RTCAudioCustomProcessingDelegate {

    private var audioFilter: AudioFilter?

    func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {}

    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        var audioBuffer = audioBuffer
        audioFilter?.applyEffect(to: &audioBuffer)
    }

    func audioProcessingRelease() {}

    func setAudioFilter(_ audioFilter: AudioFilter?) {
        self.audioFilter = audioFilter
    }
}
