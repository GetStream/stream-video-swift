//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Contract for handling CallKit calls when microphone permission is
/// missing while the app runs in the background.
protocol CallKitMissingPermissionPolicyProtocol {

    /// Decide whether reporting the call should proceed.
    ///
    /// Throw to block reporting (e.g., when permission is missing in the
    /// background).
    func reportCall() throws
}
