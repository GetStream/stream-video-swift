//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

protocol CameraPermissionProviding {

    var systemPermission: PermissionStore.Permission { get }

    func requestPermission(_ completion: @escaping (Bool) -> Void)
}

final class StreamCameraPermissionProvider: CameraPermissionProviding {
    var systemPermission: PermissionStore.Permission {
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

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice
            .requestAccess(for: .video, completionHandler: completion)
    }
}
