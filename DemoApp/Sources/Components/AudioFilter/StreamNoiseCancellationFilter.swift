//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoNoiseCancellation
import StreamWebRTC

final class StreamNoiseCancellationFilter: AudioFilter {

    private let filter: NoiseCancellationFilter

    fileprivate init(_ filter: NoiseCancellationFilter) {
        self.filter = filter
    }

    // MARK: - AudioFilter

    var id: String { "krisp-noise-cancellation-\(filter.name)" }

    func initialize(sampleRate: Int, channels: Int) {
        log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
        filter.initialize(sampleRate: sampleRate, channels: channels)
    }

    func applyEffect(to buffer: inout RTCAudioBuffer) {
        log.debug("AudioFilter:\(id) processing channels:\(buffer.channels) frames:\(buffer.frames).")
        filter.process(&buffer)
    }

    func release() {
        log.debug("AudioFilter:\(id) release.")
        filter.release()
    }
}

extension StreamNoiseCancellationFilter {
    static let no1 = StreamNoiseCancellationFilter(.no1)
    static let no2 = StreamNoiseCancellationFilter(.no2)
    static let no3 = StreamNoiseCancellationFilter(.no3)
}
