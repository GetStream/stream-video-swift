//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SortParamRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var direction: Int?
    public var field: String?

    public init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
    }
    
    public static func == (lhs: SortParamRequest, rhs: SortParamRequest) -> Bool {
        lhs.direction == rhs.direction &&
            lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(direction)
        hasher.combine(field)
    }
}
