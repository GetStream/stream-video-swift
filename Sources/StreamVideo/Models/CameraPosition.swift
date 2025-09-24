//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The camera position.
public enum CameraPosition: Sendable, Equatable, CustomStringConvertible {
    case front
    case back
    case other(CaptureDeviceProtocol)

    public var description: String {
        switch self {
        case .front:
            ".front"
        case .back:
            ".back"
        case let .other(device):
            ".other(\(device))"
        }
    }

    public func next() -> CameraPosition {
        switch self {
        case .front:
            .back
        case .back:
            .front
        case .other:
            .front
        }
    }

    public static func == (lhs: CameraPosition, rhs: CameraPosition) -> Bool {
        switch (lhs, rhs) {
        case (.front, .front):
            true

        case (.back, .back):
            true

        case let (.other(lDevice), other(rDevice)):
            lDevice.uniqueID == rDevice.uniqueID
            
        default:
            false
        }
    }
}

extension AVCaptureDevice.Position {

    init(_ source: CameraPosition) {
        switch source {
        case .front:
            self = .front
        case .back:
            self = .back
        case let .other(device):
            self = device.position
        }
    }
}
