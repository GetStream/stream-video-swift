//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice.Position: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .unspecified:
            return ".unspecified"
        case .back:
            return ".back"
        case .front:
            return ".front"
        @unknown default:
            return ".unknown(\(rawValue)"
        }
    }
}
