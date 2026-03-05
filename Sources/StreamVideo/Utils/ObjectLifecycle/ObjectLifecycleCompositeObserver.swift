//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Forwards lifecycle events to multiple observers.
    final class CompositeObserver: Observing, @unchecked Sendable {
        private let observers: [Observing]

        /// Creates a composite observer.
        /// - Parameter observers: The observers to forward events to.
        init(_ observers: [Observing]) {
            self.observers = observers
        }

        /// Creates a composite observer.
        /// - Parameter observers: The observers to forward events to.
        convenience init(_ observers: Observing...) {
            self.init(observers)
        }

        /// Forwards an event to all configured observers.
        /// - Parameter event: The incoming lifecycle event.
        func record(_ event: Event) {
            observers.forEach { $0.record(event) }
        }
    }
}
