//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryMembersRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    public var filterConditions: [String: RawJSON]?
    public var id: String
    public var limit: Int?
    public var next: String?
    public var prev: String?
    /// Array of sort parameters
    public var sort: [SortParamRequest]?
    public var type: String

    public init(
        filterConditions: [String: RawJSON]? = nil,
        id: String,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest]? = nil,
        type: String
    ) {
        self.filterConditions = filterConditions
        self.id = id
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.type = type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(filterConditions, forKey: .filterConditions)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encode(type, forKey: .type)
    }
}

extension QueryMembersRequest: Hashable {
    public static func == (lhs: QueryMembersRequest, rhs: QueryMembersRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.id == rhs.id &&
            lhs.limit == rhs.limit &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.sort == rhs.sort &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(id)
        hasher.combine(limit)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(sort)
        hasher.combine(type)
    }
}
