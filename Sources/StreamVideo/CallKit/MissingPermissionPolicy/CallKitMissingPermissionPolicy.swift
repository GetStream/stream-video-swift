//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

/// An enumeration that defines different policies for handling CallKit
/// calls when microphone permissions are missing.
///
/// When an incoming CallKit call is received while the app is in the
/// background and microphone permission has not been granted, this policy
/// determines how the app should respond. This is particularly important
/// for privacy and security reasons, as accessing the microphone without
/// proper permissions can lead to crashes or security violations.
///
/// ## Available Policies
///
/// - `.none`: No action is taken when permissions are missing. The call
///   will proceed normally, which may lead to issues if the microphone
///   is actually needed.
/// - `.endCall`: The call is automatically ended with an error when
///   permissions are missing, ensuring proper handling and user awareness.
///
/// ## Usage Example
///
/// ```swift
/// let callKitService = CallKitService()
/// // Set policy to end calls when permissions are missing
/// callKitService.missingPermissionPolicy = .endCall
/// ```
///
/// - Note: The default policy is `.endCall` for security reasons.
public enum CallKitMissingPermissionPolicy: CustomStringConvertible {

    /// A policy that takes no action when microphone permissions are
    /// missing. The call will proceed regardless of permission status.
    ///
    /// - Warning: Using this policy may cause issues if the app attempts
    ///   to access the microphone without proper permissions.
    case none

    /// A policy that ends the call with an error when microphone
    /// permissions are missing while the app is in the background.
    ///
    /// This is the recommended policy for handling missing permissions,
    /// as it ensures proper error handling and prevents security issues.
    case endCall

    /// A human-readable description of the policy.
    ///
    /// - Returns: A string representation of the current policy case.
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case .endCall:
            return ".endCall"
        }
    }

    /// Returns the appropriate policy implementation based on the current
    /// case.
    ///
    /// This property provides access to the concrete implementation of the
    /// `CallKitMissingPermissionPolicyProtocol` that corresponds to the
    /// selected policy case.
    ///
    /// - Returns: An instance conforming to
    ///   `CallKitMissingPermissionPolicyProtocol`.
    var policy: CallKitMissingPermissionPolicyProtocol {
        switch self {
        case .none:
            return NoOp()
        case .endCall:
            return EndCall()
        }
    }
}
