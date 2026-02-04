//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation
import StreamWebRTC

extension RTCVideoRotation {
    var cgOrientation: CGImagePropertyOrientation {
        switch self {
        case ._0:
            return .up
        case ._90:
            return .left
        case ._180:
            return .down
        case ._270:
            return .right
        @unknown default:
            return .up
        }
    }
}
