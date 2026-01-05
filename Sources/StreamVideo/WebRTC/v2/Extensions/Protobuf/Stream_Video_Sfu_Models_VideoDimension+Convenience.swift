//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Extension providing convenience initializers for `Stream_Video_Sfu_Models_VideoDimension`.
extension Stream_Video_Sfu_Models_VideoDimension {

    /// Initializes a `Stream_Video_Sfu_Models_VideoDimension` from a `CGSize`.
    ///
    /// - Parameter size: The `CGSize` representing width and height in points.
    /// - Converts the `CGSize` dimensions into the required `UInt32` format.
    init(_ size: CGSize) {
        height = UInt32(size.height)
        width = UInt32(size.width)
    }
}
