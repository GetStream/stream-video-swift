//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy implementation where CallKit is always available.
///
/// This policy ignores regional or other constraints.
struct CallKitAlwaysAvailabilityPolicy: CallKitAvailabilityPolicyProtocol {
    /// CallKit is always available with this policy.
    var isAvailable: Bool { true }
}
