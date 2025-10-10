//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
        appendInterpolation(value ?? "nil" as CustomStringConvertible)
    }

    mutating func appendInterpolation<T: AnyObject>(_ value: T) {
        if let convertible = value as? CustomStringConvertible {
            appendInterpolation(convertible)
        } else {
            appendInterpolation("\(Unmanaged.passUnretained(value).toOpaque())")
        }
    }
}
