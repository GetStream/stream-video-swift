//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Bound: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var inclusive: Bool
    public var value: Float

    public init(inclusive: Bool, value: Float) {
        self.inclusive = inclusive
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case inclusive
        case value
    }
    
    public static func == (lhs: Bound, rhs: Bound) -> Bool {
        lhs.inclusive == rhs.inclusive &&
            lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(inclusive)
        hasher.combine(value)
    }
}
