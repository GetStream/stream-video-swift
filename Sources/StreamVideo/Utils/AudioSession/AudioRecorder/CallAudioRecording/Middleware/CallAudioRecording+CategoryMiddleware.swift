//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    final class CategoryMiddleware: Middleware<CallAudioRecording> {
        @Injected(\.audioStore) private var audioStore

        private var cancellable: AnyCancellable?

        override init() {
            super.init()

            cancellable = audioStore
                .publisher(\.category)
                .filter { $0 != .playAndRecord || $0 != .record }
                .sink { [weak self] _ in self?.dispatcher?(.setIsRecording(false)) }
        }
    }
}
