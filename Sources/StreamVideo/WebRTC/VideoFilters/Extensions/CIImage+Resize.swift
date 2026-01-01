//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation

extension CIImage {

    /// Resizes the image to a specified target size while maintaining aspect ratio.
    ///
    /// This method creates a new `CIImage` instance resized to the provided `targetSize`
    /// while preserving the original image's aspect ratio. It uses the Lanczos resampling filter
    /// for high-quality scaling.
    ///
    /// - Parameters:
    ///   - targetSize: The desired size for the resized image.
    ///
    /// - Returns: A new `CIImage` instance resized to the target size, or nil if an error occurs.
    func resize(_ targetSize: CGSize) -> CIImage? {
        // Compute scale and corrective aspect ratio
        let scale = targetSize.height / (extent.height)
        let aspectRatio = targetSize.width / ((extent.width) * scale)

        // Apply resizing
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: scale), forKey: kCIInputScaleKey)
        filter.setValue(NSNumber(value: aspectRatio), forKey: kCIInputAspectRatioKey)
        return filter.outputImage
    }
}
