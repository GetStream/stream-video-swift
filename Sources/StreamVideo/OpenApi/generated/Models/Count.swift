//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Count: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var approximate: Bool
    public var value: Int

    public init(approximate: Bool, value: Int) {
        self.approximate = approximate
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case approximate
        case value
    }
    
    public static func == (lhs: Count, rhs: Count) -> Bool {
        lhs.approximate == rhs.approximate &&
            lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(approximate)
        hasher.combine(value)
    }
}
