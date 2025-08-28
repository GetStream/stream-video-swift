//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallKitMissingPermissionPolicy {
    
    /// A no-operation policy implementation that allows CallKit calls to
    /// proceed regardless of microphone permission status.
    ///
    /// This policy provides a permissive approach to handling CallKit
    /// calls when microphone permissions may be missing. It performs no
    /// checks and takes no action, allowing the call to proceed in all
    /// cases.
    ///
    /// ## Behavior
    ///
    /// The policy always allows calls to proceed without checking:
    /// - Application state (foreground/background)
    /// - Microphone permission status
    /// - Any other conditions
    ///
    /// ## Use Cases
    ///
    /// This policy might be appropriate when:
    /// - The app handles permissions checks elsewhere in the call flow
    /// - Testing or development scenarios where permission checks should
    ///   be bypassed
    /// - The app design ensures permissions are always granted before
    ///   CallKit is used
    ///
    /// ## Warnings
    ///
    /// Using this policy may lead to:
    /// - Runtime crashes if the system attempts to access the microphone
    ///   without proper permissions
    /// - Security and privacy violations
    /// - Poor user experience if calls fail silently due to permission
    ///   issues
    ///
    /// ## Usage
    ///
    /// This policy is automatically used when
    /// `CallKitMissingPermissionPolicy.none` is selected:
    ///
    /// ```swift
    /// callKitService.missingPermissionPolicy = .none
    /// ```
    ///
    /// - Warning: This policy should be used with caution. The `.endCall`
    ///   policy is recommended for production applications to ensure
    ///   proper permission handling.
    final class NoOp: CallKitMissingPermissionPolicyProtocol {
        
        /// Reports that the call should always proceed.
        ///
        /// This implementation performs no checks and never throws an
        /// error, effectively allowing all calls to proceed regardless
        /// of permission status or application state.
        ///
        /// - Note: The empty implementation is intentional - this is a
        ///   no-operation policy that takes no action.
        func reportCall() throws { /* No-op */ }
    }
}
