//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

extension PermissionStore {

    public enum StoreAction: Sendable {
        case setMicrophonePermission(Permission)
        case requestMicrophonePermission

        case setCameraPermission(Permission)
        case requestCameraPermission

        case setPushNotificationPermission(Permission)
        case requestPushNotificationPermission(UNAuthorizationOptions)
    }
}
