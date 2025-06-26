//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Publisher where Output: Sendable {

    /// Fetches the next value emitted by the publisher.
    ///
    /// - Parameters:
    ///   - dropFirst: The number of elements to drop before returning the next value.
    ///   - timeout: The maximum time to wait for the first value.
    ///   - scheduler: The scheduler on which to perform the timeout.
    /// - Returns: The first `Output` value emitted by the publisher.
    /// - Throws: A `ClientError` if the timeout occurs before a value is emitted or if the publisher completes without emitting a value.
    func nextValue<S: Scheduler>(
        dropFirst: Int? = nil,
        timeout: TimeInterval? = nil,
        on scheduler: S = DispatchQueue.main,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Output where Failure == Error {
        let dropPublisher = {
            if let dropFirst {
                return self.dropFirst(dropFirst).eraseToAnyPublisher()
            } else {
                return self.eraseToAnyPublisher()
            }
        }()

        let timeoutPublisher = {
            if let timeout, timeout > 0 {
                return dropPublisher
                    .timeout(
                        .seconds(timeout),
                        scheduler: scheduler,
                        customError: { ClientError("Operation timed out.", file, line) }
                    )
                    .eraseToAnyPublisher()
            } else {
                return dropPublisher
            }
        }()

        guard
            let result = await timeoutPublisher.eraseAsAsyncStream().first(where: { _ in true })
        else {
            throw ClientError("Nil value found when expected non-nil.", file, line)
        }
        return result
    }

    /// Fetches the next value emitted by the publisher.
    ///
    /// - Parameters:
    ///   - dropFirst: The number of elements to drop before returning the next value.
    ///   - timeout: The maximum time to wait for the first value.
    ///   - scheduler: The scheduler on which to perform the timeout.
    /// - Returns: The first `Output` value emitted by the publisher.
    /// - Throws: A `ClientError` if the publisher completes without emitting a value.
    func nextValue<S: Scheduler>(
        dropFirst: Int? = nil,
        timeout: TimeInterval? = nil,
        on scheduler: S = DispatchQueue.main,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Output where Failure == Never {
        let dropPublisher = {
            if let dropFirst {
                return self.dropFirst(dropFirst).eraseToAnyPublisher()
            } else {
                return self.eraseToAnyPublisher()
            }
        }()

        let timeoutPublisher = {
            if let timeout, timeout > 0 {
                return dropPublisher
                    .timeout(.seconds(timeout), scheduler: scheduler)
                    .eraseToAnyPublisher()
            } else {
                return dropPublisher
            }
        }()

        guard
            let result = await timeoutPublisher.eraseAsAsyncStream().first(where: { _ in true })
        else {
            throw ClientError("Nil value found when expected non-nil.", file, line)
        }
        return result
    }
}
