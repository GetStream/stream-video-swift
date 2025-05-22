//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: (some CustomStringConvertible)?) {
        appendInterpolation(value ?? "nil" as CustomStringConvertible)
    }
}
