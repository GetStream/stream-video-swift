//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Protocol for providing camera permission management.
protocol CameraPermissionProviding {
    
    /// The current camera permission status from the system.
    var systemPermission: PermissionStore.Permission { get }
    
    /// Requests camera permission from the user.
    /// - Parameter completion: Called with `true` if permission granted.
    func requestPermission(_ completion: @Sendable @escaping (Bool) -> Void)
}

/// Default implementation for camera permission management using AVFoundation.
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

    func requestPermission(_ completion: @Sendable @escaping (Bool) -> Void) {
        AVCaptureDevice
            .requestAccess(for: .video, completionHandler: completion)
    }
}
