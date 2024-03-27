//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class DemoVoiceProcessor: NSObject, RTCAudioCustomProcessingDelegate {

    private var audioFilter: AudioFilter?
    private var sampleRateHz = 16000

    func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        self.sampleRateHz = sampleRateHz
        print("======== \(sampleRateHz)")
    }

    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        var audioBuffer = audioBuffer
        audioFilter?.applyEffect(to: &audioBuffer, sampleRate: sampleRateHz)
    }

    func audioProcessingRelease() {}

    func setAudioFilter(_ audioFilter: AudioFilter?) {
        self.audioFilter = audioFilter
    }
}
