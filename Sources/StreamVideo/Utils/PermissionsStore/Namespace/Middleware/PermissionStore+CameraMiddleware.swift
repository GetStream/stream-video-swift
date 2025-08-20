//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension PermissionStore {

    final class CameraMiddleware: Middleware<Namespace>, @unchecked Sendable {

        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { dispatcher?.dispatch(.setCameraPermission(systemPermission)) }
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
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                return .unknown
            case .restricted:
                return .denied
            case .denied:
                return .denied
            case .authorized:
                return .granted
            @unknown default:
                return .unknown
            }
        }

        private func requestPermission() {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] in
                self?.dispatcher?.dispatch(.setCameraPermission($0 ? .granted : .denied))
            }
        }
    }
}
