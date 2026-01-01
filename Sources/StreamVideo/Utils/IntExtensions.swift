//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    func roundUp(toMultipleOf powerOfTwo: Self) -> Self {
        precondition(powerOfTwo > 0 && powerOfTwo & (powerOfTwo &- 1) == 0)
        return (self + (powerOfTwo &- 1)) & (0 &- powerOfTwo)
    }
}
