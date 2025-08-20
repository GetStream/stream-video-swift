//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import UserNotifications

extension PermissionStore {

    final class PushNotificationsMiddleware: Middleware<Namespace>, @unchecked Sendable {

        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { didUpdate(dispatcher) }
        }

        override func apply(
            state: PermissionStore.StoreState,
            action: PermissionStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .requestPushNotificationPermission(options):
                requestPermission(with: options)

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func systemPermission() async -> Permission {
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

        private func didUpdate(_ dispatcher: Store<Namespace>.Dispatcher?) {
            guard dispatcher != nil else {
                return
            }
            Task { [weak self] in
                guard let self else {
                    return
                }
                let permission = await systemPermission()
                dispatcher?.dispatch(.setPushNotificationPermission(permission))
            }
        }

        private func requestPermission(with options: UNAuthorizationOptions) {
            UNUserNotificationCenter
                .current()
                .requestAuthorization(options: options) { [weak self] in
                    self?.didUpdateRequestAuthorization(granted: $0, error: $1)
                }
        }

        private func didUpdateRequestAuthorization(granted: Bool, error: Error?) {
            if let error {
                log.error(error)
                dispatcher?.dispatch(.setPushNotificationPermission(.unknown))
            } else {
                dispatcher?.dispatch(.setPushNotificationPermission(granted ? .granted : .denied))
            }
        }
    }
}
