//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Receives lifecycle events emitted by tracked objects.
    protocol Observing: AnyObject, Sendable {
        /// Records a lifecycle event.
        /// - Parameter event: The event to record.
        func record(_ event: Event)
    }
}
