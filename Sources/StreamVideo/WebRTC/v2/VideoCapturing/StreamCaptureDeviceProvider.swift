//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public enum CaptureDeviceType: Hashable { case builtIn, continuity, external }

/// A protocol defining methods for providing capture devices.
public protocol CaptureDeviceProviding {

    var availableDevices: [CaptureDeviceProtocol] { get }

    func devices(of type: CaptureDeviceType) -> [CaptureDeviceProtocol]

    /// Returns a capture device for the specified CameraPosition.
    /// - Parameter position: The position of the Camera.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: CameraPosition) -> CaptureDeviceProtocol?

    func cameraPosition(for device: CaptureDeviceProtocol) -> CameraPosition?
}

/// A class that provides capture devices.
final class StreamCaptureDeviceProvider: CaptureDeviceProviding {

    /// Indicates whether to use a fallback device if the specified one is not found.
    private let useFallback: Bool

    private let builtInDevices: [CaptureDeviceProtocol]
    private let continuityDevices: [CaptureDeviceProtocol]
    private let externalDevices: [CaptureDeviceProtocol]
    private let typeMap: [String: CaptureDeviceType]

    var availableDevices: [CaptureDeviceProtocol] {
        builtInDevices + continuityDevices + externalDevices
    }

    convenience init(
        useFallback: Bool = true
    ) {
        self.init(
            builtInDevices: AVCaptureDevice.builtInDevices,
            continuityDevices: AVCaptureDevice.continuityDevices,
            externalDevices: AVCaptureDevice.externalDevices,
            useFallback: useFallback
        )
    }

    /// Initializes a new instance of StreamCaptureDeviceProvider.
    /// - Parameter useFallback: Indicates whether to use a fallback device.
    init(
        builtInDevices: [AVCaptureDevice],
        continuityDevices: [AVCaptureDevice],
        externalDevices: [AVCaptureDevice],
        useFallback: Bool
    ) {
        self.builtInDevices = builtInDevices
        self.continuityDevices = continuityDevices
        self.externalDevices = externalDevices
        self.useFallback = useFallback
        typeMap = {
            var result = [String: CaptureDeviceType]()
            builtInDevices.forEach { result[$0.uniqueID] = .builtIn }
            continuityDevices.forEach { result[$0.uniqueID] = .continuity }
            externalDevices.forEach { result[$0.uniqueID] = .external }
            return result
        }()
    }

    func devices(of type: CaptureDeviceType) -> [CaptureDeviceProtocol] {
        switch type {
        case .builtIn:
            builtInDevices
        case .continuity:
            continuityDevices
        case .external:
            externalDevices
        }
    }

    /// Returns a capture device for the specified CameraPosition.
    /// - Parameter position: The position of the Camera.
    /// - Returns: A capture device conforming to CaptureDeviceProtocol.
    func device(for position: CameraPosition) -> CaptureDeviceProtocol? {
        switch position {
        case .front:
            if let result = builtInDevices.first(where: { $0.position == .front }) {
                result
            } else if
                useFallback,
                let result = AVCaptureDevice.default(for: .video),
                result.position == .front {
                result
            } else {
                nil
            }
        case .back:
            if let result = builtInDevices.first(where: { $0.position == .back }) {
                result
            } else if
                useFallback,
                let result = AVCaptureDevice.default(for: .video),
                result.position == .back {
                result
            } else {
                nil
            }
        case let .other(device):
            device
        }
    }

    func cameraPosition(for device: CaptureDeviceProtocol) -> CameraPosition? {
        guard let type = typeMap[device.uniqueID] else {
            return nil
        }

        switch type {
        case .builtIn:
            return device.position == .front ? .front : .back
        case .continuity:
            return .other(device)
        case .external:
            return .other(device)
        }
    }
}

/// A key for injecting a CaptureDeviceProviding instance.
enum CaptureDeviceProviderKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: CaptureDeviceProviding = StreamCaptureDeviceProvider()
}

/// An extension to manage injected values.
extension InjectedValues {
    /// The capture device provider.
    public var captureDeviceProvider: CaptureDeviceProviding {
        get { Self[CaptureDeviceProviderKey.self] }
        set { Self[CaptureDeviceProviderKey.self] = newValue }
    }
}
