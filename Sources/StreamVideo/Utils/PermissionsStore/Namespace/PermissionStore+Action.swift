//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

extension PermissionStore {
    
    /// Actions that drive the permissions state machine.
    ///
    /// Use these to update cached statuses or to trigger system prompts
    /// via middleware responsible for requesting permissions.
    public enum StoreAction: Sendable, Equatable, StoreActionBoxProtocol {
        /// Updates the cached microphone permission.
        /// - Parameter permission: New status (unknown/requesting/denied/granted).
        case setMicrophonePermission(Permission)

        /// Requests microphone access from the system.
        ///
        /// Middleware observes this action, invokes the platform API, then
        /// dispatches ``setMicrophonePermission(_:)`` with the result.
        case requestMicrophonePermission

        /// Updates the cached camera permission.
        /// - Parameter permission: New status (unknown/requesting/denied/granted).
        case setCameraPermission(Permission)

        /// Requests camera access from the system.
        /// Middleware should handle the prompt and follow‑up update.
        case requestCameraPermission

        /// Updates the cached push notification permission.
        /// - Parameter permission: New status (unknown/requesting/denied/granted).
        case setPushNotificationPermission(Permission)

        /// Requests push notification authorization.
        /// - Parameter options: Authorization options to request.
        case requestPushNotificationPermission(UNAuthorizationOptions)
    }
}
