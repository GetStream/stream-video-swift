//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enumeration that describes the source from which a call was joined.
///
/// Use `JoinSource` to indicate whether the join action originated from within
/// the app's own UI or through a system-level interface such as CallKit.
/// This helps distinguish the user's entry point and can be used to customize
/// behavior or analytics based on how the call was initiated.
enum JoinSource {
    /// Indicates that the call was joined from within the app's UI.
    case inApp

    /// Indicates that the call was joined via CallKit integration.
    case callKit
}
