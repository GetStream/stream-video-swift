//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

extension CallKitMissingPermissionPolicy {

    /// A policy implementation that ends CallKit calls when microphone
    /// permissions are missing while the app is in the background.
    ///
    /// This policy provides a secure way to handle incoming CallKit calls
    /// when the application lacks the necessary microphone permissions. It
    /// checks both the application state and permission status before
    /// allowing a call to proceed.
    ///
    /// ## Behavior
    ///
    /// The policy will throw an error and end the call when:
    /// - The application is running in the background AND
    /// - Microphone permission has not been granted
    ///
    /// If either condition is not met (app is in foreground OR microphone
    /// permission is granted), the call will proceed normally.
    ///
    /// ## Security Considerations
    ///
    /// This policy helps prevent security and privacy issues that could
    /// arise from attempting to access the microphone without proper
    /// permissions. It ensures that users are aware of permission
    /// requirements and prevents potential crashes or security violations.
    ///
    /// ## Usage
    ///
    /// This policy is automatically used when
    /// `CallKitMissingPermissionPolicy.endCall` is selected:
    ///
    /// ```swift
    /// callKitService.missingPermissionPolicy = .endCall
    /// ```
    final class EndCall: CallKitMissingPermissionPolicyProtocol {

        /// Injected dependency for checking system permissions.
        @Injected(\.permissions) private var permissions
        
        /// Injected dependency for checking application state.
        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        /// Reports whether the call should proceed based on current
        /// permissions and application state.
        ///
        /// This method checks if the app is in the background and lacks
        /// microphone permissions. If both conditions are true, it throws
        /// an error to prevent the call from proceeding.
        ///
        /// - Throws: `ClientError` with message "CallKit missing microphone
        ///   permission." when the app is in the background and lacks
        ///   microphone permission.
        ///
        /// - Note: This method only blocks calls when BOTH conditions are
        ///   met: background execution AND missing permissions. This allows
        ///   foreground calls to proceed (where the user can be prompted
        ///   for permissions) while protecting against background security
        ///   issues.
        func reportCall() throws {
            let isRunningInForeground = applicationStateAdapter.state == .foreground
            let hasMicrophonePermission = permissions.hasMicrophonePermission

            guard
                !isRunningInForeground, !hasMicrophonePermission
            else {
                return
            }

            throw ClientError("CallKit missing microphone permission.")
        }
    }
}
