//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import UserNotifications

extension PermissionStore {
    
    /// Middleware that handles push notification permission requests and
    /// state updates.
    final class PushNotificationsMiddleware: Middleware<Namespace>, @unchecked Sendable {

        private let permissionProvider: PushNotificationsPermissionProviding

        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { didUpdate(dispatcher) }
        }

        init(
            permissionProvider: PushNotificationsPermissionProviding = StreamPushNotificationsPermissionProvider()
        ) {
            self.permissionProvider = permissionProvider
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
            await permissionProvider.systemPermission()
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
            permissionProvider.requestPermission(with: options) { [weak self] in
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
