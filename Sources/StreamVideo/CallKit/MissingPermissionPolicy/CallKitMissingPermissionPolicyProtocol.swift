//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines the interface for handling CallKit calls when
/// microphone permissions are missing.
///
/// Types conforming to this protocol implement specific strategies for
/// dealing with incoming CallKit calls when the application lacks the
/// necessary microphone permissions. This is particularly relevant when
/// the app is running in the background and needs to handle calls safely.
///
/// ## Conformance Requirements
///
/// Types conforming to this protocol must implement the `reportCall()`
/// method, which determines whether to allow or block the call based on
/// the current permission status and application state.
///
/// ## Default Implementations
///
/// The framework provides two default implementations:
/// - `CallKitMissingPermissionPolicy.NoOp`: A no-operation implementation
///   that allows calls to proceed regardless of permission status.
/// - `CallKitMissingPermissionPolicy.EndCall`: An implementation that
///   throws an error when permissions are missing, effectively ending
///   the call.
///
/// ## Custom Implementations
///
/// You can create custom implementations to handle missing permissions
/// according to your app's specific requirements:
///
/// ```swift
/// struct CustomPermissionPolicy: CallKitMissingPermissionPolicyProtocol {
///     func reportCall() throws {
///         // Custom logic for handling missing permissions
///         if shouldBlockCall() {
///             throw CustomError("Call blocked due to permissions")
///         }
///     }
/// }
/// ```
protocol CallKitMissingPermissionPolicyProtocol {

    /// Reports whether the call should proceed based on the current
    /// permission status.
    ///
    /// This method is called when a CallKit call is being reported. It
    /// should check the current microphone permission status and
    /// application state to determine whether the call should be allowed
    /// to proceed or should be terminated.
    ///
    /// - Throws: An error if the call should be terminated due to missing
    ///   permissions. The specific error thrown depends on the
    ///   implementation.
    ///
    /// - Note: This method is typically called from a background thread
    ///   when handling incoming VoIP push notifications.
    func reportCall() throws
}
