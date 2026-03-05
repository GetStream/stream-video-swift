//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Lifecycle transitions emitted for tracked objects.
    enum Transition: String, Sendable {
        /// Emitted when a tracked object is created.
        case initialized
        /// Emitted when a tracked object's metadata changes.
        case metadataUpdated
        /// Emitted when a tracked object is deallocated.
        case deinitialized
    }
}
