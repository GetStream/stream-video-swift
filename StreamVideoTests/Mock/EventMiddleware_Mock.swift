//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware, @unchecked Sendable {
    var closure: (WrappedEvent) -> WrappedEvent?

    init(closure: @escaping (WrappedEvent) -> WrappedEvent? = { event in event }) {
        self.closure = closure
    }

    func handle(event: WrappedEvent) -> WrappedEvent? {
        closure(event)
    }
}
