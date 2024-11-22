//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Extension adding utility for retrieving frame rate range of an `AVCaptureDevice.Format`.
extension AVCaptureDevice.Format {

    var dimensions: CMVideoDimensions {
        CMVideoFormatDescriptionGetDimensions(formatDescription)
    }

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

extension Array where Element == AVCaptureDevice.Format {
    enum Requirement {
        case area(preferredDimensions: CMVideoDimensions)
        case frameRate(preferredFrameRate: Int)
        case minimumAreaDifference(preferredDimensions: CMVideoDimensions)
    }

    func first(with requirements: [Requirement]) -> AVCaptureDevice.Format? {
        var possibleResults = self

        for requirement in requirements {
            switch requirement {
            case let .area(preferredDimensions: preferredDimensions):
                possibleResults = possibleResults.filter { $0.dimensions.area >= preferredDimensions.area }
            case let .frameRate(preferredFrameRate: preferredFrameRate):
                possibleResults = possibleResults.filter { $0.frameRateRange.contains(preferredFrameRate) }
            case let .minimumAreaDifference(preferredDimensions):
                let result = possibleResults
                    .min { $0.areaDiff(preferredDimensions) < $1.areaDiff(preferredDimensions) }
                if let result {
                    possibleResults = [result]
                } else {
                    possibleResults = []
                }
            }
        }

        return possibleResults.first
    }
}
