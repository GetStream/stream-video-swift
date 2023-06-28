//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

func executeTask<Output>(
    retryPolicy: RetryPolicy,
    task: () async throws -> Output
) async throws -> Output {
    try await executeTask(
        retryPolicy: retryPolicy,
        task: task,
        retries: 0
    )
}

func executeTask<Output>(
    retryPolicy: RetryPolicy,
    task: () async throws -> Output,
    retries: Int
) async throws -> Output {
    do {
        return try await task()
    } catch {
        if retries < retryPolicy.maxRetries {
            let delay = UInt64(retryPolicy.delay(retries) * 1_000_000_000)
            try await Task.sleep(nanoseconds: delay)
            if retryPolicy.runPrecondition() {
                return try await executeTask(
                    retryPolicy: retryPolicy,
                    task: task,
                    retries: retries + 1
                )
            } else {
                throw error
            }
        } else {
            throw error
        }
    }

}

struct RetryPolicy {
    let maxRetries: Int
    let delay: (Int) -> TimeInterval
    var runPrecondition: () -> Bool = { true }
}

extension RetryPolicy {
    static let fastAndSimple = RetryPolicy(maxRetries: 3) { quickDelay(retries: $0) }
    
    static func fastCheckValue(_ condition: @escaping () -> Bool) -> RetryPolicy {
        RetryPolicy(
            maxRetries: 3,
            delay: { quickDelay(retries: $0) },
            runPrecondition: condition
        )
    }
    
    static func neverGonnaGiveYouUp(_ condition: @escaping () -> Bool) -> RetryPolicy {
        RetryPolicy(
            maxRetries: 30,
            delay: { delay(retries: $0) },
            runPrecondition: condition
        )
    }
    
    static func quickDelay(retries: Int) -> TimeInterval {
        TimeInterval.random(in: 0.25...0.5)
    }
    
    static func delay(retries: Int) -> TimeInterval {
        return TimeInterval.random(in: 0.5...2.5)
    }
}
