//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC

final class DemoVoiceProcessor: NSObject, RTCAudioCustomProcessingDelegate {

    private final class AtomicBox<V> {
        private var _wrappedValue: V
        private let queue = UnfairQueue()
        var wrappedValue: V {
            get { queue.sync { _wrappedValue } }
            set { queue.sync { _wrappedValue = newValue } }
        }

        init(_ initial: V) {
            _wrappedValue = initial
        }
    }

    private var audioFilter: AtomicBox<AudioFilter?> = .init(nil)

    private var sampleRate: Int = 0
    private var channels: Int = 0

    // MARK: - Accessors

    func setAudioFilter(_ audioFilter: AudioFilter?) {
        log.debug("AudioFilter updated \(self.audioFilter.wrappedValue?.id ?? "nil") → \(audioFilter?.id ?? "nil")")

        let oldValue = self.audioFilter.wrappedValue
        self.audioFilter.wrappedValue = nil
        oldValue?.release()

        if let newValue = audioFilter, sampleRate > 0, channels > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self, sampleRate, channels] in
                guard let self else { return }
                newValue.initialize(
                    sampleRate: sampleRate,
                    channels: channels
                )
                self.audioFilter.wrappedValue = newValue
            }
        }
    }

    // MARK: - RTCAudioCustomProcessingDelegate
    
    func audioProcessingInitialize(
        sampleRate sampleRateHz: Int,
        channels: Int
    ) {
        log.debug("AudioSession updated sampleRate:\(sampleRateHz) channels:\(channels)")
        sampleRate = sampleRateHz
        self.channels = channels

        audioFilter.wrappedValue?.initialize(
            sampleRate: sampleRateHz,
            channels: channels
        )
    }

    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        guard let audioFilter = audioFilter.wrappedValue else { return }
        var audioBuffer = audioBuffer
        audioFilter.applyEffect(to: &audioBuffer)
    }

    func audioProcessingRelease() {
        let _audioFilter = audioFilter.wrappedValue
        setAudioFilter(nil)
        _audioFilter?.release()
    }
}
