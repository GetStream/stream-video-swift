//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Publisher {
    func nextValue(dropFirst: Int = 0) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.dropFirst(dropFirst).sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
            )
        }
    }
}
