//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Publisher where Output: Sendable {

    /// Retrieves the next value from the publisher after optionally skipping the initial values.
    ///
    /// - Parameter dropFirst: The number of initial values to skip. Defaults to 0.
    /// - Returns: The next value emitted by the publisher.
    /// - Throws: An error if the publisher completes with a failure.
    func nextValue(
        dropFirst: Int = 0,
        timeout: TimeInterval? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var receivedValue = false
            var timeoutWorkItem: DispatchWorkItem?

            if let timeout = timeout {
                let workItem = DispatchWorkItem {
                    if !receivedValue {
                        continuation.resume(
                            throwing: ClientError("Operation timed out", file, line)
                        )
                        cancellable?.cancel()
                    }
                }
                timeoutWorkItem = workItem
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: workItem)
            }

            cancellable = self.dropFirst(dropFirst).sink(
                receiveCompletion: { completion in
                    timeoutWorkItem?.cancel()
                    switch completion {
                    case .finished:
                        if !receivedValue {
                            continuation.resume(
                                throwing: ClientError("Publisher completed with no value", file, line)
                            )
                        }
                    case let .failure(error):
                        if !receivedValue {
                            continuation.resume(throwing: error)
                        }
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    timeoutWorkItem?.cancel()
                    guard !receivedValue else { return }
                    receivedValue = true
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
            )
        }
    }
}
