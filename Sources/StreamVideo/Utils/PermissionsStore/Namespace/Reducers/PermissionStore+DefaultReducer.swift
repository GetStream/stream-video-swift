//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PermissionStore {
    
    /// Default reducer that handles permission state updates based on
    /// dispatched actions.
    final class DefaultReducer: Reducer<Namespace>, @unchecked Sendable {

        override func reduce(
            state: PermissionStore.StoreState,
            action: PermissionStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> PermissionStore.StoreState {
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
