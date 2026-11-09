//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SortParamRequest: Sendable, Encodable, JSONEncodable {
    /// Direction of sorting, 1 for Ascending, -1 for Descending, default is 1. One of: -1, 1
    public let direction: Int?
    /// Name of field to sort by
    public let field: String?

    public init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(field, forKey: .field)
    }
}

extension SortParamRequest: Hashable {
    public static func == (lhs: SortParamRequest, rhs: SortParamRequest) -> Bool {
        lhs.direction == rhs.direction &&
            lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(direction)
        hasher.combine(field)
    }
}
