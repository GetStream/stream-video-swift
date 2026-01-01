//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// AudioFilter protocol defines the structure for audio filtering implementations.
public protocol AudioFilter: Sendable {
    /// Unique identifier for the audio filter.
    var id: String { get }

    /// Initializes the audio filter with specified sample rate and number of channels.
    func initialize(sampleRate: Int, channels: Int)

    /// Applies the defined audio effect to the given audio buffer.
    func applyEffect(to audioBuffer: inout RTCAudioBuffer)

    /// Releases resources associated with the audio filter.
    func release()
}

/// Extension to provide default implementations for certain methods of the AudioFilter protocol.
public extension AudioFilter {
    /// Default implementation for initializing the audio filter.
    func initialize(sampleRate: Int, channels: Int) {
        log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
    }

    /// Default implementation for releasing the audio filter.
    func release() {
        log.debug("AudioFilter:\(id) release.")
    }
}
