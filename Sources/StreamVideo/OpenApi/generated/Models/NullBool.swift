//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class NullBool: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var hasValue: Bool?
    public var value: Bool?

    public init(hasValue: Bool? = nil, value: Bool? = nil) {
        self.hasValue = hasValue
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hasValue = "HasValue"
        case value = "Value"
    }
    
    public static func == (lhs: NullBool, rhs: NullBool) -> Bool {
        lhs.hasValue == rhs.hasValue &&
            lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasValue)
        hasher.combine(value)
    }
}
