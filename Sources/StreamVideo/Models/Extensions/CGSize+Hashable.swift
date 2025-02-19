//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation

extension CGSize: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
