//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC

final class DemoVoiceProcessor: NSObject, RTCAudioCustomProcessingDelegate {

    private actor State {
        private(set) var audioFilter: AudioFilter?
        private(set) var sampleRate: Int = 0
        private(set) var channels: Int = 0

        func setAudioFilter(_ value: AudioFilter?) {
            audioFilter?.release()
            audioFilter = value
        }

        func setSampleRate(_ value: Int) {
            self.sampleRate = value
        }

        func setChannels(_ value: Int) {
            self.channels = value
        }
    }

    private var state: State = .init()

    // MARK: - Accessors

    func setAudioFilter(_ audioFilter: AudioFilter?) {
        Task {
            let oldValue = await state.audioFilter
            log.debug("AudioFilter updated \(oldValue?.id ?? "nil") → \(audioFilter?.id ?? "nil")")

            let sampleRate = await state.sampleRate
            let channels = await state.channels

            if
                let newValue = audioFilter,
                sampleRate > 0,
                channels > 0 {
                newValue.initialize(sampleRate: sampleRate, channels: channels)
                await state.setAudioFilter(newValue)
            } else {
                await state.setAudioFilter(nil)
            }
        }
    }

    // MARK: - RTCAudioCustomProcessingDelegate

    func audioProcessingInitialize(
        sampleRate sampleRateHz: Int,
        channels: Int
    ) {
        log.debug("AudioSession updated sampleRate:\(sampleRateHz) channels:\(channels)")
        Task {
            await state.setSampleRate(sampleRateHz)
            await state.setChannels(channels)
            await state.audioFilter?.initialize(
                sampleRate: sampleRateHz,
                channels: channels
            )
        }
    }

    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        Task {
            guard let audioFilter = await state.audioFilter else { return }
            var audioBuffer = audioBuffer
            audioFilter.applyEffect(to: &audioBuffer)
        }
    }

    func audioProcessingRelease() {
        Task {
            await state.setAudioFilter(nil)
        }
    }
}
