//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The normaliser computes the percentage values or value of the provided value.
class AudioValuePercentageNormaliser {
    let valueRange: ClosedRange<Float> = -50...0

    /// Compute the range between the min and max values
    lazy var delta: Float = valueRange.upperBound - valueRange.lowerBound

    init() {}

    /// Computes the value's percentage representation with respect to the maximum
    /// and minimum values in the provided range. The result is will be in the range `0...1`.
    /// - Parameter value: The value to be transformed to percentage relative to the provided
    /// valueRange.
    /// - Returns: a normalised Float value
    func normalise(_ value: Float) -> Float {
        if value < valueRange.lowerBound {
            0
        } else if value > valueRange.upperBound {
            1
        } else {
            abs((value - valueRange.lowerBound) / delta)
        }
    }
}
