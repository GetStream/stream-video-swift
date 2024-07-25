//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

enum TimeoutError: Error {
    case timedOut
}

extension Publisher {

    /// Retrieves the next value from the publisher after optionally skipping the initial values.
    ///
    /// - Parameter dropFirst: The number of initial values to skip. Defaults to 0.
    /// - Returns: The next value emitted by the publisher.
    /// - Throws: An error if the publisher completes with a failure.
    func nextValue(
        dropFirst: Int = 0,
        timeout: TimeInterval? = nil
    ) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var receivedValue = false // Track whether a value has been received
            var timeoutWorkItem: DispatchWorkItem?

            if let timeout = timeout {
                let workItem = DispatchWorkItem {
                    if !receivedValue {
                        continuation.resume(throwing: TimeoutError.timedOut)
                        cancellable?.cancel()
                    }
                }
                timeoutWorkItem = workItem
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: workItem)
            }

            cancellable = self.dropFirst(dropFirst).sink(
                receiveCompletion: { completion in
                    timeoutWorkItem?.cancel()
                    if case let .failure(error) = completion {
                        if !receivedValue {
                            continuation.resume(throwing: error) // Resume only if value hasn't been received
                        }
                        cancellable?.cancel()
                    }
                },
                receiveValue: { value in
                    timeoutWorkItem?.cancel()
                    if !receivedValue {
                        continuation.resume(returning: value) // Resume only if value hasn't been received
                        receivedValue = true
                    }
                    cancellable?.cancel()
                }
            )
        }
    }
}
