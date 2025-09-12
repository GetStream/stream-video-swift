//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class AudioCustomProcessingModule: NSObject, RTCAudioCustomProcessingDelegate, @unchecked Sendable {

    enum Event {
        case audioProcessingInitialize(sampleRateHz: Int, channels: Int)
        case audioProcessingProcess(RTCAudioBuffer)
        case audioProcessingRelease
    }

    private let subject: PassthroughSubject<Event, Never> = .init()
    var publisher: AnyPublisher<Event, Never> { subject.eraseToAnyPublisher() }

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

    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        subject.send(.audioProcessingProcess(audioBuffer))
    }

    func audioProcessingRelease() {
        subject.send(.audioProcessingRelease)
    }
}
