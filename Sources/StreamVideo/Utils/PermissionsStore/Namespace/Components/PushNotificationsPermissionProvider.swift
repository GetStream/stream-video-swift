//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

/// Protocol for providing push notifications permission management.
protocol PushNotificationsPermissionProviding {
    
    /// Retrieves the current push notification permission status.
    /// - Returns: The current permission status.
    func systemPermission() async -> PermissionStore.Permission
    
    /// Requests push notification permission from the user.
    /// - Parameters:
    ///   - options: The notification authorization options requested.
    ///   - completion: Called with grant status and optional error.
    func requestPermission(
        with options: UNAuthorizationOptions,
        _ completion: @Sendable @escaping (Bool, Error?) -> Void
    )
}

/// Default implementation for push notifications permission management using
/// UserNotifications framework.
final class StreamPushNotificationsPermissionProvider: PushNotificationsPermissionProviding {
    func systemPermission() async -> PermissionStore.Permission {
        // UNUserNotificationCenter cannot be initialised correctly during
        // tests. For this reason we disable it.
        // Reference: The related crash looks like this
        // __bundleProxyForCurrentProcess is nil: mainBundle.bundleURL__
        guard !SystemEnvironment.isTests else {
            return .unknown
        }
        let authorizationStatus = await UNUserNotificationCenter
            .current()
            .notificationSettings()
            .authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            return .unknown
        case .provisional:
            return .granted
        case .denied:
            return .denied
        case .authorized:
            return .granted
        case .ephemeral:
            return .granted
        @unknown default:
            return .unknown
        }
    }

    func requestPermission(
        with options: UNAuthorizationOptions,
        _ completion: @Sendable @escaping (Bool, Error?) -> Void
    ) {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: options,
                completionHandler: completion
            )
    }
}
