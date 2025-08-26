//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

extension PermissionStore {
    
    /// Actions that can be dispatched to the permission store.
    public enum StoreAction: Sendable, Equatable {
        case setMicrophonePermission(Permission)
        case requestMicrophonePermission

        case setCameraPermission(Permission)
        case requestCameraPermission

        case setPushNotificationPermission(Permission)
        case requestPushNotificationPermission(UNAuthorizationOptions)
    }
}
