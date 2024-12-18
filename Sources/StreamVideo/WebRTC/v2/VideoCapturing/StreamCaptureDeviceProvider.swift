//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class StreamCaptureDeviceProvider {

    private let firstResultIfMiss: Bool

    private var devices: [AVCaptureDevice] {
        RTCCameraVideoCapturer.captureDevices()
    }

    init(firstResultIfMiss: Bool = true) {
        self.firstResultIfMiss = firstResultIfMiss
    }

    func device(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let deviceFound = devices.first(where: { $0.position == position }) {
            return deviceFound
        } else if firstResultIfMiss {
            return devices.first
        } else {
            return nil
        }
    }

    func device(for position: CameraPosition) -> AVCaptureDevice? {
        device(for: position == .front ? AVCaptureDevice.Position.front : .back)
    }
}

extension StreamCaptureDeviceProvider: InjectionKey {
    static var currentValue: StreamCaptureDeviceProvider = .init()
}

extension InjectedValues {
    var captureDeviceProvider: StreamCaptureDeviceProvider {
        get { Self[StreamCaptureDeviceProvider.self] }
        set { Self[StreamCaptureDeviceProvider.self] = newValue }
    }
}