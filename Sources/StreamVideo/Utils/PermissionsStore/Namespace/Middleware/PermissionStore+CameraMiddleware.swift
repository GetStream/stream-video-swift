//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension PermissionStore {
    
    /// Middleware that handles camera permission requests and state updates.
    final class CameraMiddleware: Middleware<Namespace>, @unchecked Sendable {

        private let permissionProvider: CameraPermissionProviding
        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { dispatcher?.dispatch(.setCameraPermission(systemPermission)) }
        }

        init(
            permissionProvider: CameraPermissionProviding = StreamCameraPermissionProvider()
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
            case .requestCameraPermission:
                requestPermission()

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private var systemPermission: Permission {
            permissionProvider.systemPermission
        }

        private func requestPermission() {
            permissionProvider.requestPermission { [weak self] in
                self?
                    .dispatcher?
                    .dispatch(.setCameraPermission($0 ? .granted : .denied))
            }
        }
    }
}
