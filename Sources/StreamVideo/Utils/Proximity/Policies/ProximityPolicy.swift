//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Protocol defining behavior for handling device proximity changes during calls.
/// Implementations can react to proximity state changes with custom logic.
public protocol ProximityPolicy: Sendable, CustomStringConvertible {
    /// Unique identifier for the policy implementation
    static var identifier: ObjectIdentifier { get }

    /// Called when device proximity state changes during a call
    /// - Parameters:
    ///   - proximity: New proximity state of the device
    ///   - call: Call instance where the proximity change occurred
    func didUpdateProximity(_ proximity: ProximityState, on call: Call)
}

extension ProximityPolicy {
    /// Default description implementation using the policy's identifier
    public var description: String { "\(Self.identifier)" }
}
