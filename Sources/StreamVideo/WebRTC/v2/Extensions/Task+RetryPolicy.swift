//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Task where Failure == Error {

    @discardableResult
    init(
        retryPolicy: Task.RetryPolicy,
        operation: @escaping () async throws -> Success
    ) {
        self.init {
            var currentAttempt = 0
            while currentAttempt < retryPolicy.maxAttempts {
                do {
                    if await retryPolicy.preCondition() {
                        let result = try await operation()
                        return result
                    } else {
                        throw RetryingError.preConditionFailed
                    }
                } catch {
                    currentAttempt += 1
                    if currentAttempt >= retryPolicy.maxAttempts || !retryPolicy.shouldRetry(error) {
                        throw error
                    }
                    try await Task<Never, Never>.sleep(
                        nanoseconds: UInt64(
                            retryPolicy.retryDelay(currentAttempt) * 1_000_000_000
                        )
                    )
                }
            }
            throw RetryingError.maxAttemptsReached
        }
    }

    struct RetryPolicy {
        var maxAttempts: Int
        var retryDelay: (Int) -> TimeInterval
        var shouldRetry: (Failure) -> Bool = { _ in true }
        var preCondition: () async -> Bool = { true }

        private static func quickDelay(_ retries: Int) -> TimeInterval {
            TimeInterval.random(in: 0.25...0.5)
        }

        private static func delay(_ retries: Int) -> TimeInterval {
            TimeInterval.random(in: 0.5...2.5)
        }

        static func fastAndSimple() -> RetryPolicy {
            .init(maxAttempts: 3, retryDelay: { quickDelay($0) })
        }

        static func fastCheckValue(
            _ preCondition: @escaping () -> Bool
        ) -> RetryPolicy {
            .init(
                maxAttempts: 3,
                retryDelay: { quickDelay($0) },
                preCondition: preCondition
            )
        }

        static func neverGonnaGiveYouUp(
            _ preCondition: @escaping () async -> Bool
        ) -> RetryPolicy {
            .init(
                maxAttempts: 30,
                retryDelay: { delay($0) },
                preCondition: preCondition
            )
        }
    }

    enum RetryingError: Error {
        case maxAttemptsReached
        case preConditionFailed
    }
}
