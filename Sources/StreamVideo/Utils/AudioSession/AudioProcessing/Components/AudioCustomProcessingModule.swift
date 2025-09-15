//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Bridges `RTCAudioCustomProcessingDelegate` callbacks into a Combine stream.
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
        subject.send(.audioProcessingProcess(audioBuffer))
    }

    /// RTCAudioCustomProcessingDelegate
    func audioProcessingRelease() {
        subject.send(.audioProcessingRelease)
    }
}
