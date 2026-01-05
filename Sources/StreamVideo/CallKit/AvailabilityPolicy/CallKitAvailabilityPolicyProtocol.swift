//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol defining the requirements for CallKit availability policies.
public protocol CallKitAvailabilityPolicyProtocol {
    /// Indicates whether CallKit is available under the policy.
    var isAvailable: Bool { get }
}
