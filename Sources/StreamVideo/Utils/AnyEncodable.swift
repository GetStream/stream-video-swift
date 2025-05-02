//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct AnyEncodable: Encodable, Equatable, @unchecked Sendable {
    private let _encode: (Encoder) throws -> Void
    private let _isEqual: (Any) -> Bool

    var value: Any

    init?<T>(_ value: T) {
        if let anyEncodable = value as? AnyEncodable {
            self = anyEncodable
        } else {
            guard let _value = value as? Encodable else {
                return nil
            }
            self.init(_value)
        }
    }

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
        _isEqual = { _ in false }

        self.value = value
    }

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

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }

    static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        lhs._isEqual(rhs.value)
    }
}
