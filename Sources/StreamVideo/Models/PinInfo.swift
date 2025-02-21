//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides info whether the user is pinned.
public struct PinInfo: Sendable, Hashable {
    /// Determines if it's a local or a remote pin.
    public let isLocal: Bool
    /// The date of pinning.
    public let pinnedAt: Date
}
