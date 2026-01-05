//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    /// Appends a textual representation of an optional, replacing `nil` with
    /// the literal string `"nil"`.
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
        appendInterpolation(value ?? "nil" as CustomStringConvertible)
    }

    /// Appends object references using `CustomStringConvertible` when
    /// available, otherwise falls back to the memory address.
    mutating func appendInterpolation<T: AnyObject>(_ value: T) {
        if let convertible = value as? CustomStringConvertible {
            appendInterpolation(convertible)
        } else {
            appendInterpolation("\(Unmanaged.passUnretained(value).toOpaque())")
        }
    }
}
