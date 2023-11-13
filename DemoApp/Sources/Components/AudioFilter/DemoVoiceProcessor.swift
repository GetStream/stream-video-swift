//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

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
