//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy that defines when CallKit is available.
/// It can be configured to always enable CallKit, enable it based on the user's
/// region, or use a custom implementation.
public enum CallKitAvailabilityPolicy: CustomStringConvertible {

    /// CallKit is always available, regardless of conditions.
    case always

    /// CallKit availability is determined based on the user's region.
    case regionBased

    /// CallKit availability is determined by a custom policy.
    /// - Parameter policy: A custom policy implementing `CallKitAvailabilityPolicyProtocol`.
    case custom(CallKitAvailabilityPolicyProtocol)

    /// A textual description of the availability policy.
    ///
    /// - Returns: A string representation of the policy.
    public var description: String {
        switch self {
        case .always:
            ".always"
        case .regionBased:
            ".regionBased"
        case let .custom(policy):
            ".custom(\(policy))"
        }
    }

    /// The underlying policy implementation based on the selected availability.
    ///
    /// - Returns: An instance conforming to `CallKitAvailabilityPolicyProtocol`.
    var policy: CallKitAvailabilityPolicyProtocol {
        switch self {
        case .always:
            CallKitAlwaysAvailabilityPolicy()
        case .regionBased:
            CallKitRegionBasedAvailabilityPolicy()
        case let .custom(policy):
            policy
        }
    }
}
