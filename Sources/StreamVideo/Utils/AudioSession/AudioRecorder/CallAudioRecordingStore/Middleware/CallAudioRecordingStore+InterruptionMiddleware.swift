//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecordingStore {

    final class InterruptionMiddleware: CallAudioRecordingMiddleware {
        @Injected(\.audioStore) private var audioStore

        weak var store: CallAudioRecordingStore?

        private var cancellable: AnyCancellable?

        init(_ store: CallAudioRecordingStore) {
            self.store = store

            cancellable = audioStore
                .publisher(\.isInterrupted)
                .sink { [weak self] in self?.store?.dispatch(.setIsInterrupted($0)) }
        }

        func apply(
            state: CallAudioRecordingStore.State,
            action: CallAudioRecordingAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            /* No-op */
        }
    }
}
