//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockPermissionsStore: @unchecked Sendable {

    enum Function {
        case requestMicrophonePermission
        case requestCameraPermission
        case requestPushNotificationPermission
    }

    private let mockReducer: MockReducer<PermissionStore.Namespace> = .init()
    private let mockMiddleware: MockMiddleware<PermissionStore.Namespace> = .init()

    private(set) lazy var mockStore: Store<PermissionStore.Namespace> = PermissionStore
        .Namespace
        .store(
            initialState: .init(
                microphonePermission: .granted,
                cameraPermission: .granted,
                pushNotificationPermission: .granted
            ),
            reducers: [
                PermissionStore.DefaultReducer(),
                mockReducer
            ],
            middleware: [mockMiddleware]
        )

    init() {
        _ = mockStore
        InjectedValues[\.permissions] = .init(store: mockStore)
    }

    func dismantle() {
        InjectedValues[\.permissions] = .shared
    }

    func timesCalled(_ function: Function) -> Int {
        mockReducer
            .inputs
            .filter {
                switch (function, $0.action) {
                case (.requestMicrophonePermission, .requestMicrophonePermission):
                    return true

                case (.requestCameraPermission, .requestCameraPermission):
                    return true

                case (.requestPushNotificationPermission, .requestPushNotificationPermission):
                    return true

                default:
                    return false
                }
            }
            .count
    }

    func stubMicrophonePermission(_ permission: PermissionStore.Permission) {
        mockStore.dispatch(.setMicrophonePermission(permission))
    }

    func stubCameraPermission(_ permission: PermissionStore.Permission) {
        mockStore.dispatch(.setCameraPermission(permission))
    }

    func stubPushNotificationPermission(_ permission: PermissionStore.Permission) {
        mockStore.dispatch(.setPushNotificationPermission(permission))
    }
}
