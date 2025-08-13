//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    final class InterruptionMiddleware: Middleware<CallAudioRecording> {
        @Injected(\.audioStore) private var audioStore

        private var cancellable: AnyCancellable?

        override init() {
            super.init()

            cancellable = audioStore
                .publisher(\.isInterrupted)
                .sink { [weak self] in self?.dispatcher?(.setIsInterrupted($0)) }
        }
    }
}
