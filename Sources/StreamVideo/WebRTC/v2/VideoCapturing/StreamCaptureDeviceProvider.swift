//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol CaptureDeviceProviding {
    func device(for position: AVCaptureDevice.Position) -> CaptureDeviceProtocol?
    func device(for position: CameraPosition) -> CaptureDeviceProtocol?
}

final class StreamCaptureDeviceProvider: CaptureDeviceProviding {

    private let useFallback: Bool

    private var devices: [AVCaptureDevice] {
        RTCCameraVideoCapturer.captureDevices()
    }

    init(useFallback: Bool = true) {
        self.useFallback = useFallback
    }

    func device(for position: AVCaptureDevice.Position) -> CaptureDeviceProtocol? {
        if let deviceFound = devices.first(where: { $0.position == position }) {
            return deviceFound
        } else if useFallback {
            return devices.first
        } else {
            return nil
        }
    }

    func device(for position: CameraPosition) -> CaptureDeviceProtocol? {
        device(for: position == .front ? AVCaptureDevice.Position.front : .back)
    }
}

enum CaptureDeviceProviderKey: InjectionKey {
    static var currentValue: CaptureDeviceProviding = StreamCaptureDeviceProvider()
}

extension InjectedValues {
    var captureDeviceProvider: CaptureDeviceProviding {
        get { Self[CaptureDeviceProviderKey.self] }
        set { Self[CaptureDeviceProviderKey.self] = newValue }
    }
}
