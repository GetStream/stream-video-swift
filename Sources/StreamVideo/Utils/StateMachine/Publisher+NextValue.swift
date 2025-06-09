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
        try await withThrowingTaskGroup(of: Output.self) { group in
            var cancellable: AnyCancellable?
            let dropFirstPublisher = self.dropFirst(dropFirst).eraseToAnyPublisher()

            group.addTask { [dropFirstPublisher] in
                try await withCheckedThrowingContinuation { continuation in
                    var receivedValue = false
                    cancellable = dropFirstPublisher.sink(
                        receiveCompletion: { completion in
                            if case let .failure(error) = completion {
                                if !receivedValue {
                                    continuation.resume(throwing: error)
                                }
                            }
                        },
                        receiveValue: { value in
                            if !receivedValue {
                                receivedValue = true
                                if let error = value as? Error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: value)
                                }
                            }
                        }
                    )
                }
            }

            if let timeout = timeout {
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw ClientError("Operation timed out", file, line)
                }
            }

            let result = try await group.next()!
            group.cancelAll()
            cancellable?.cancel()
            return result
        }
    }
}
