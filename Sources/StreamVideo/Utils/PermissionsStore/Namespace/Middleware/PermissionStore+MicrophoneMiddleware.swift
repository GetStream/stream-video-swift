//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension PermissionStore {
    
    /// Middleware that handles microphone permission requests and state
    /// updates.
    final class MicrophoneMiddleware: Middleware<Namespace>, @unchecked Sendable {

        private let permissionProvider: MicrophonePermissionProviding

        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { dispatcher?.dispatch(.setMicrophonePermission(systemPermission)) }
        }

        init(
            permissionProvider: MicrophonePermissionProviding = StreamMicrophonePermissionProvider()
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
            case .requestMicrophonePermission:
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
                    .dispatch(.setMicrophonePermission($0 ? .granted : .denied))
            }
        }
    }
}
