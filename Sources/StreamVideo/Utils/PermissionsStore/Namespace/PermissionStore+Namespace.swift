//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {

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
