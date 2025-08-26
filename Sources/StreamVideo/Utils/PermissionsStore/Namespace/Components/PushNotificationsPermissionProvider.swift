//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

protocol PushNotificationsPermissionProviding {

    func systemPermission() async -> PermissionStore.Permission

    func requestPermission(
        with options: UNAuthorizationOptions,
        _ completion: @escaping (Bool, Error?) -> Void
    )
}

final class StreamPushNotificationsPermissionProvider: PushNotificationsPermissionProviding {
    func systemPermission() async -> PermissionStore.Permission {
        /// UNUserNotificationCenter cannot be initialised correctly during tests. For this reason
        /// we disable it.
        /// - Reference: The related crash looks like this
        /// __bundleProxyForCurrentProcess is nil: mainBundle.bundleURL__
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
        _ completion: @escaping (Bool, Error?) -> Void
    ) {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: options,
                completionHandler: completion
            )
    }
}
