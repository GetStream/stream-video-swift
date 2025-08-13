//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol StoreNamespace {
    associatedtype State: Equatable
    associatedtype Action: Sendable

    static var identifier: String { get }

    static func reducers() -> [Reducer<Self>]

    static func middleware() -> [Middleware<Self>]

    static func logger() -> StoreLogger<Self>

    static func executor() -> StoreExecutor<Self>

    static func store(initialState: State) -> Store<Self>
}

extension StoreNamespace {

    static func reducers() -> [Reducer<Self>] { [] }

    static func middleware() -> [Middleware<Self>] { [] }

    static func logger() -> StoreLogger<Self> { .init() }

    static func executor() -> StoreExecutor<Self> { .init() }

    static func store(
        initialState: State
    ) -> Store<Self> {
        .init(
            identifier: Self.identifier,
            initialState: initialState,
            reducers: Self.reducers(),
            middleware: Self.middleware(),
            logger: Self.logger(),
            executor: Self.executor()
        )
    }
}
