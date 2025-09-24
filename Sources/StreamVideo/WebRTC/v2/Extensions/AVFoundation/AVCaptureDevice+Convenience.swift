//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVCaptureDevice {

    static var builtInDevices: [AVCaptureDevice] {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInWideAngleCamera,
                .builtInDualWideCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        .devices

        if #available(iOS 16.0, *) {
            return devices.filter { $0.isContinuityCamera == false }
        } else {
            return devices
        }
    }

    static var continuityDevices: [AVCaptureDevice] {
        guard #available(iOS 16.0, *) else {
            return []
        }

        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInWideAngleCamera,
                .builtInDualWideCamera
            ],
            mediaType: .video,
            position: .front
        )
        .devices
        .filter(\.isContinuityCamera)
    }

    static var externalDevices: [AVCaptureDevice] {
        guard #available(iOS 17.0, *) else {
            return []
        }

        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .external
            ],
            mediaType: .video,
            position: .front
        )
        .devices
    }
}
