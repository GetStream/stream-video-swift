//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import Foundation
import UIKit

extension UIInterfaceOrientation {
    /// Values of `CGImagePropertyOrientation` define the position of the pixel coordinate origin
    /// point (0,0) and the directions of the coordinate axes relative to the intended display orientation of
    /// the image. While `UIInterfaceOrientation` uses a different point as its (0,0), this extension
    /// provides a simple way of mapping device orientation to image orientation.
    var cgOrientation: CGImagePropertyOrientation {
        switch self {
        /// Handle known portrait orientations
        case .portrait:
            return .left

        case .portraitUpsideDown:
            return .right

        /// Handle known landscape orientations
        case .landscapeLeft:
            return .up

        case .landscapeRight:
            return .down

        /// Unknown case, return `up` for consistency
        case .unknown:
            return .up

        /// Default case for unknown orientations or future additions
        /// Returns `up` for consistency.
        @unknown default:
            return .up
        }
    }
}

#endif // #if canImport(UIKit)
