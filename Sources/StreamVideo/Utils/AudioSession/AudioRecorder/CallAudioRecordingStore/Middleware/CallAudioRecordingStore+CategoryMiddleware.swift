//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecordingStore {

    final class CategoryMiddleware: CallAudioRecordingMiddleware {
        @Injected(\.audioStore) private var audioStore

        weak var store: CallAudioRecordingStore?

        private var cancellable: AnyCancellable?

        init(_ store: CallAudioRecordingStore) {
            self.store = store

            cancellable = audioStore
                .publisher(\.category)
                .filter { $0 != .playAndRecord || $0 != .record }
                .sink { [weak self] _ in self?.store?.dispatch(.setIsRecording(false)) }
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
