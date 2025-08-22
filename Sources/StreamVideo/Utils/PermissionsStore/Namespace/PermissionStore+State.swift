//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {

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

    public struct StoreState: Equatable, CustomStringConvertible {
        public var microphonePermission: Permission
        public var cameraPermission: Permission
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
