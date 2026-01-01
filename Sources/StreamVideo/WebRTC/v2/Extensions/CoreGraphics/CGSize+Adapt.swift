//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation

extension CGSize {
    /// Adjusts the size to fit within the specified maximum size while maintaining the aspect ratio
    /// and ensuring dimensions are safe multiples.
    ///
    /// - Parameter maxSize: The target size to fit within.
    /// - Returns: A new `CGSize` with adjusted dimensions.
    func adjusted(toFit maxSize: CGFloat) -> CGSize {
        guard width > 0 && height > 0 && maxSize > 0 else {
            return CGSize(width: 16, height: 16) // Minimum safe size
        }

        // Determine aspect-fit dimensions
        let isWider = width >= height
        let ratio = isWider ? height / width : width / height
        let fitWidth = isWider ? maxSize : ratio * maxSize
        let fitHeight = isWider ? ratio * maxSize : maxSize

        // Ensure dimensions are safe multiples of 2 and at least 16
        let safeWidth = max(16, ceil(fitWidth / 2) * 2)
        let safeHeight = max(16, ceil(fitHeight / 2) * 2)

        return CGSize(width: safeWidth, height: safeHeight)
    }
}
