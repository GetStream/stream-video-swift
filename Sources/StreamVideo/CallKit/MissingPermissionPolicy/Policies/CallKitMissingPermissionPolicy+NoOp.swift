//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallKitMissingPermissionPolicy {
    
    /// No-op policy. Always allows reporting, regardless of permissions or
    /// app state.
    final class NoOp: CallKitMissingPermissionPolicyProtocol {
        
        /// Always allow.
        func reportCall() throws { /* No-op */ }
    }
}
