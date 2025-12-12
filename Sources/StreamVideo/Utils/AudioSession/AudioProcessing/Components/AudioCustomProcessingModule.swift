//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Bridges `RTCAudioCustomProcessingDelegate` callbacks into a Combine stream.
///
/// The delegate must stay extremely light-weight because WebRTC calls it while
/// holding an internal lock; any expensive work risks exceeding the ~10 ms
/// cadence and the native adapter will start skipping frames entirely. By
/// immediately forwarding each callback into a Combine publisher we decouple
/// the real-time audio path from the rest of the SDK: reducers, middleware, and
/// filters can subscribe (and hop to their own schedulers if needed) without
/// lengthening the time spent inside the delegate. This keeps capture responsive
/// while still letting higher layers observe every event and apply effects.
///
/// The module publishes structured events that middleware can observe to update
/// audio processing configuration and feed buffers into active filters.

final class AudioCustomProcessingModule: NSObject, RTCAudioCustomProcessingDelegate, @unchecked Sendable {

    /// High‑level events emitted by the WebRTC audio custom processing hooks.
    enum Event {
        /// WebRTC initialized processing with the given format.
        case audioProcessingInitialize(sampleRateHz: Int, channels: Int)
        /// A capture buffer is ready to be processed by filters.
        case audioProcessingProcess(RTCAudioBuffer)
        /// WebRTC is releasing the processing resources.
        case audioProcessingRelease
    }

    private let subject: PassthroughSubject<Event, Never> = .init()
    /// Event stream used by store middleware to react to audio callbacks.
    var publisher: AnyPublisher<Event, Never> { subject.eraseToAnyPublisher() }

    /// Direct callback used for in-place filtering; must return within ~10 ms.
    var processingHandler: ((RTCAudioBuffer) -> Void)?

    /// RTCAudioCustomProcessingDelegate
    func audioProcessingInitialize(
        sampleRate sampleRateHz: Int,
        channels: Int
    ) {
        subject.send(
            .audioProcessingInitialize(
                sampleRateHz: sampleRateHz,
                channels: channels
            )
        )
    }

    /// RTCAudioCustomProcessingDelegate
    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        // Synchronous filtering happens via `processingHandler` so we can finish
        // within WebRTC's ~10 ms processing budget; the native adapter wraps this
        // delegate in a trylock and simply drops the frame if we block. Running
        // Combine here would introduce scheduling/queue hops that blow the budget.
        processingHandler?(audioBuffer)

        // Downstream observers only need metadata (channel count, logs, etc.), so
        // we enqueue the Combine event after the synchronous work; this publish is
        // fire-and-forget and keeps the hot path lock-free.
        subject.send(.audioProcessingProcess(audioBuffer))
    }

    /// RTCAudioCustomProcessingDelegate
    func audioProcessingRelease() {
        subject.send(.audioProcessingRelease)
    }
}
