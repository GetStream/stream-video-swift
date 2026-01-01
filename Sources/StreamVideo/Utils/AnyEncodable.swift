//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type-erased `Encodable` value with optional equality support.
///
/// `AnyEncodable` enables encoding of values whose concrete type is
/// unknown at compile time. It captures the encoding logic using a
/// closure and optionally supports equality if initialized with an
/// `Equatable` value.
struct AnyEncodable: Encodable, Equatable, @unchecked Sendable {
    /// Encodes the value to an `Encoder`. This closure is assigned during
    /// initialization and stores the encoding logic for the wrapped value.
    private let _encode: (Encoder) throws -> Void
    /// Compares the stored value against another. If the original value was
    /// `Equatable`, this closure performs type-safe equality comparison.
    private let _isEqual: (Any) -> Bool

    /// The underlying value, which must conform to `Encodable`.
    ///
    /// If equality support is desired, the value must also conform to
    /// `Equatable` and be initialized using the corresponding initializer.
    let value: Any

    /// Initializes from an existing `AnyEncodable` to avoid re-wrapping.
    ///
    /// This initializer allows preserving the original encoding and equality
    /// closures when passing or storing `AnyEncodable` values.
    init(_ value: AnyEncodable) {
        self = value
    }

    /// Initializes with an `Encodable` value, without equality support.
    ///
    /// The provided value is encoded using a closure captured at
    /// initialization time. Equality comparison will always return false.
    ///
    /// - Parameter value: The value to wrap.
    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
        _isEqual = { _ in false }

        self.value = value
    }

    /// Initializes with a value that conforms to both `Encodable` and
    /// `Equatable`, enabling equality support.
    ///
    /// This version stores a type-safe equality closure that will return
    /// true only if the other value has the same type and is equal.
    ///
    /// - Parameter value: The value to wrap.
    init<T: Encodable & Equatable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
        _isEqual = { other in
            guard let other = other as? T else {
                return false
            }
            return other == value
        }

        self.value = value
    }

    /// Encodes the stored value using the provided encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if the encoding process fails.
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }

    /// Compares two `AnyEncodable` instances for equality.
    ///
    /// This uses the stored equality closure. If the values were not
    /// initialized with `Equatable` conformance, this always returns false.
    ///
    /// - Parameters:
    ///   - lhs: The first `AnyEncodable` value.
    ///   - rhs: The second `AnyEncodable` value.
    /// - Returns: `true` if the wrapped values are equal.
    static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        lhs._isEqual(rhs.value)
    }
}
