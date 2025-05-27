//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Task {

    @discardableResult
    public init(
        disposableBag: DisposableBag,
        identifier: String = UUIDProviderKey.currentValue.get().uuidString,
        priority: TaskPriority? = nil,
        @_inheritActorContext block: @Sendable @escaping () async -> Success
    ) where Failure == Never {
        self.init(priority: priority) { [weak disposableBag] in
            defer { disposableBag?.completed(identifier) }
            return await block()
        }
    }

    @discardableResult
    public init(
        disposableBag: DisposableBag,
        identifier: String = UUIDProviderKey.currentValue.get().uuidString,
        priority: TaskPriority? = nil,
        @_inheritActorContext block: @Sendable @escaping () async throws -> Success
    ) where Failure == Error {
        self.init(priority: priority) { [weak disposableBag] in
            defer { disposableBag?.completed(identifier) }
            return try await block()
        }
    }
}
