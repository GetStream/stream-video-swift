//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Extension adding utility methods for `AVCaptureDevice.Format` to simplify
/// working with video capture formats, such as retrieving dimensions and
/// supported frame rates.
extension AVCaptureDevice.Format {

    /// The video dimensions (width and height in pixels) of the capture format.
    ///
    /// - Returns: A `CMVideoDimensions` structure representing the format's
    ///   width and height.
    ///
    /// This property retrieves the dimensions directly from the format's
    /// description. Useful for comparing and selecting formats based on size.
    var dimensions: CMVideoDimensions {
        CMVideoFormatDescriptionGetDimensions(formatDescription)
    }

    /// Computes the area difference between the format's dimensions and a target.
    ///
    /// - Parameter target: The target video dimensions to compare against.
    /// - Returns: An `Int32` representing the absolute difference in area
    ///   (width × height) between the format's dimensions and the target.
    ///
    /// This method is used to evaluate how closely a format's dimensions
    /// match a desired size.
    func areaDiff(_ target: CMVideoDimensions) -> Int32 {
        abs(dimensions.area - target.area)
    }

    /// The supported frame rate range for the capture device format.
    ///
    /// - Returns: A `ClosedRange<Int>` representing the minimum and maximum
    ///   frame rates supported by the format.
    ///
    /// - Note:
    ///   - This range is derived from the `videoSupportedFrameRateRanges` property.
    ///   - If no frame rate ranges are available, the range defaults to `0...0`.
    ///
    /// - Example:
    ///   ```swift
    ///   if let format = captureDevice.activeFormat {
    ///       let range = format.frameRateRange
    ///       print("Supported frame rates: \(range)")
    ///   }
    ///   ```
    var frameRateRange: ClosedRange<Int> {
        let minFrameRate = videoSupportedFrameRateRanges
            .map(\.minFrameRate)
            .min() ?? 0
        let maxFrameRate = videoSupportedFrameRateRanges
            .map(\.maxFrameRate)
            .max() ?? 0

        return (Int(minFrameRate)...Int(maxFrameRate))
    }
}
