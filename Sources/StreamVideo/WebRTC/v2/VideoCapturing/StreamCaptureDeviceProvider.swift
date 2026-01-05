//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A protocol defining methods for providing capture devices.
protocol CaptureDeviceProviding {
    /// Returns a capture device for the specified AVCaptureDevice position.
    /// - Parameter position: The position of the AVCaptureDevice.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: AVCaptureDevice.Position) -> CaptureDeviceProtocol?
    
    /// Returns a capture device for the specified CameraPosition.
    /// - Parameter position: The position of the Camera.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: CameraPosition) -> CaptureDeviceProtocol?
}

/// A class that provides capture devices.
final class StreamCaptureDeviceProvider: CaptureDeviceProviding {

    /// Indicates whether to use a fallback device if the specified one is not found.
    private let useFallback: Bool

    /// A list of available capture devices.
    private var devices: [AVCaptureDevice] {
        RTCCameraVideoCapturer.captureDevices()
    }

    /// Initializes a new instance of StreamCaptureDeviceProvider.
    /// - Parameter useFallback: Indicates whether to use a fallback device.
    init(useFallback: Bool = true) {
        self.useFallback = useFallback
    }

    /// Returns a capture device for the specified AVCaptureDevice position.
    /// - Parameter position: The position of the AVCaptureDevice.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: AVCaptureDevice.Position) -> CaptureDeviceProtocol? {
        if let deviceFound = devices.first(where: { $0.position == position }) {
            return deviceFound
        } else if useFallback {
            return devices.first
        } else {
            return nil
        }
    }

    /// Returns a capture device for the specified CameraPosition.
    /// - Parameter position: The position of the Camera.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: CameraPosition) -> CaptureDeviceProtocol? {
        device(for: position == .front ? AVCaptureDevice.Position.front : .back)
    }
}

/// A key for injecting a CaptureDeviceProviding instance.
enum CaptureDeviceProviderKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: CaptureDeviceProviding = StreamCaptureDeviceProvider()
}

/// An extension to manage injected values.
extension InjectedValues {
    /// The capture device provider.
    var captureDeviceProvider: CaptureDeviceProviding {
        get { Self[CaptureDeviceProviderKey.self] }
        set { Self[CaptureDeviceProviderKey.self] = newValue }
    }
}
