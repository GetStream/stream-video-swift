//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class NullTime: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var hasValue: Bool?
    public var value: Date?

    public init(hasValue: Bool? = nil, value: Date? = nil) {
        self.hasValue = hasValue
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hasValue = "HasValue"
        case value = "Value"
    }
    
    public static func == (lhs: NullTime, rhs: NullTime) -> Bool {
        lhs.hasValue == rhs.hasValue &&
            lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasValue)
        hasher.combine(value)
    }
}
