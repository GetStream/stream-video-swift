//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {

    final class DefaultReducer: Reducer<Namespace>, @unchecked Sendable {

        override func reduce(
            state: PermissionStore.StoreState,
            action: PermissionStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> PermissionStore.StoreState {
            var updatedState = state

            switch action {
            case let .setMicrophonePermission(permission):
                updatedState.microphonePermission = permission

            case .requestMicrophonePermission:
                updatedState.microphonePermission = .requesting

            case let .setCameraPermission(permission):
                updatedState.cameraPermission = permission

            case .requestCameraPermission:
                updatedState.cameraPermission = .requesting

            case let .setPushNotificationPermission(permission):
                updatedState.pushNotificationPermission = permission

            case .requestPushNotificationPermission:
                updatedState.pushNotificationPermission = .requesting
            }

            return updatedState
        }
    }
}
