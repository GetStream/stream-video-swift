//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Extension providing a utility for clamping values within a range.
extension Comparable {

    /// Clamps a value to ensure it lies within a specified range.
    ///
    /// - Parameter limits: A `ClosedRange` specifying the minimum and maximum
    ///   bounds for the value.
    /// - Returns: The clamped value, constrained to the given range.
    ///
    /// - Example:
    ///   ```swift
    ///   let value = 15
    ///   let clampedValue = value.clamped(to: 10...20)
    ///   print(clampedValue) // 15
    ///
    ///   let outOfBoundsValue = 25
    ///   let clampedOutOfBounds = outOfBoundsValue.clamped(to: 10...20)
    ///   print(clampedOutOfBounds) // 20
    ///   ```
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
