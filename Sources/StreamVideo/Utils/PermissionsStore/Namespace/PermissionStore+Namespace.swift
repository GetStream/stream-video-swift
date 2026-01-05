//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {
    
    /// Namespace that defines the store configuration for permission
    /// management.
    enum Namespace: StoreNamespace {
        typealias State = StoreState

        typealias Action = StoreAction

        static let identifier: String = "io.getstream.permissions"

        static func reducers() -> [Reducer<PermissionStore.Namespace>] {
            [DefaultReducer()]
        }

        static func middleware() -> [Middleware<PermissionStore.Namespace>] {
            [
                MicrophoneMiddleware(),
                CameraMiddleware(),
                PushNotificationsMiddleware()
            ]
        }
    }
}
