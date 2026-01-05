//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the StreamVideo SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    nonisolated(unsafe) static var assertionsEnabled = false
}
