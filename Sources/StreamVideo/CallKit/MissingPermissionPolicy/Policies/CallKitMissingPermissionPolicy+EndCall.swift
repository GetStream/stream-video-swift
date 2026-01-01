//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

extension CallKitMissingPermissionPolicy {

    /// Ends calls when microphone permission is missing and the app runs in
    /// the background.
    final class EndCall: CallKitMissingPermissionPolicyProtocol {

        /// Checks system permissions.
        @Injected(\.permissions) private var permissions
        
        /// Observes app state.
        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        /// Throw when in background without microphone permission.
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
