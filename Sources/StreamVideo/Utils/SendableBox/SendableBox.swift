//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Namespace for wrapping non-sendable closures in tests.
enum SendableBox {}

extension SendableBox {
    struct Value<ValueType>: @unchecked Sendable {
        let value: ValueType

        /// Creates a boxed closure for cross-actor use in tests.
        init(_ value: ValueType) {
            self.value = value
        }
    }
}

extension SendableBox {
    /// A sendable wrapper for a single-argument closure.
    struct Closure<A, Output>: @unchecked Sendable {
        typealias ValueType = (A) -> Output
        let value: ValueType

        /// Creates a boxed closure for cross-actor use in tests.
        init(_ value: @escaping ValueType) {
            self.value = value
        }
    }

    /// A sendable wrapper for a two-argument closure.
    struct Closure2<A, B, Output>: @unchecked Sendable {
        typealias ValueType = (A, B) -> Output
        let value: ValueType

        /// Creates a boxed closure for cross-actor use in tests.
        init(_ value: @escaping ValueType) {
            self.value = value
        }
    }

    /// A sendable wrapper for a three-argument closure.
    struct Closure3<A, B, C, Output>: @unchecked Sendable {
        typealias ValueType = (A, B, C) -> Output
        let value: ValueType

        /// Creates a boxed closure for cross-actor use in tests.
        init(_ value: @escaping ValueType) {
            self.value = value
        }
    }
}
