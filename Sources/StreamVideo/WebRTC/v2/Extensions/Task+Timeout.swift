//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Task where Failure == Error {

    init(
        timeout: TimeInterval,
        operation: @Sendable @escaping () async throws -> Success
    ) {
        self.init {
            try await withThrowingTaskGroup(of: Success.self) { group in
                group.addTask {
                    try await operation()
                }

                group.addTask {
                    try await Task<Never, Never>.sleep(
                        nanoseconds: UInt64(
                            timeout * 1_000_000_000
                        )
                    )
                    throw TimeoutError.timedOut
                }

                let result = try await group.next()!
                group.cancelAll()
                return result
            }
        }
    }
}
