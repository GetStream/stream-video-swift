//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {
    
    /// Represents the state of a system permission.
    public enum Permission: Equatable, Sendable, CustomStringConvertible {
        case unknown
        case requesting
        case denied
        case granted

        public var description: String {
            switch self {
            case .unknown:
                return ".unknown"
            case .requesting:
                return ".requesting"
            case .denied:
                return ".denied"
            case .granted:
                return ".granted"
            }
        }
    }

    /// The state container for all permission statuses.
    public struct StoreState: Equatable, CustomStringConvertible {
        /// The current microphone permission status.
        public var microphonePermission: Permission
        /// The current camera permission status.
        public var cameraPermission: Permission
        /// The current push notification permission status.
        public var pushNotificationPermission: Permission

        public var description: String {
            "<Permissions microphone:\(microphonePermission) camera:\(cameraPermission) pushNotifications:\(pushNotificationPermission)/>"
        }

        nonisolated(unsafe) static let initial = StoreState(
            microphonePermission: .unknown,
            cameraPermission: .unknown,
            pushNotificationPermission: .unknown
        )
    }
}
