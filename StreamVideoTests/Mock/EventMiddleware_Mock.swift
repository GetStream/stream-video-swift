//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware {
    var closure: (Event) -> Event?

    init(closure: @escaping (Event) -> Event? = { event in event }) {
        self.closure = closure
    }

    func handle(event: Event) -> Event? {
        closure(event)
    }
}
