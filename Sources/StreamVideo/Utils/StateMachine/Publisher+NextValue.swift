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
    ///
    /// - Important: When subscribing to a timer use the registrationHandler to receive the reference
    /// to the cancellable, so you can effectively cancel it. Otherwise the Timer will keep posting updates
    func nextValue(
        dropFirst: Int = 0,
        timeout: TimeInterval? = nil,
        registrationHandler: ((AnyCancellable) -> Void)? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Output {
        let publisher = dropFirst > 0
            ? self.dropFirst(dropFirst).eraseToAnyPublisher()
            : eraseToAnyPublisher()
        if let timeout {
            return try await Task(
                timeoutInSeconds: timeout,
                file: file,
                function: function,
                line: line
            ) {
                if let value = try await publisher._nextValue(file: file, line: line) {
                    return value
                } else {
                    throw ClientError("Missing value", file, line)
                }
            }.value
        } else {
            if let value = try await publisher._nextValue(file: file, line: line) {
                return value
            } else {
                throw ClientError("Missing value", file, line)
            }
        }
    }
}
