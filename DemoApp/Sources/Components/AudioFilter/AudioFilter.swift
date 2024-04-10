//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

protocol AudioFilter {

    var id: String { get }

    func initialize(sampleRate: Int, channels: Int)

    func applyEffect(to audioBuffer: inout RTCAudioBuffer)

    func release()
}

extension AudioFilter {

    func initialize(sampleRate: Int, channels: Int) {
        log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
    }

    func release() {
        log.debug("AudioFilter:\(id) release.")
    }
}
