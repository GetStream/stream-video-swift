//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallStatsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    public var filterConditions: [String: RawJSON]?
    public var limit: Int?
    public var next: String?
    public var prev: String?
    /// Array of sort parameters
    public var sort: [SortParamRequest]?

    public init(
        filterConditions: [String: RawJSON]? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest]? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(filterConditions, forKey: .filterConditions)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encodeIfPresent(sort, forKey: .sort)
    }
}

extension QueryCallStatsRequest: Hashable {
    public static func == (lhs: QueryCallStatsRequest, rhs: QueryCallStatsRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.limit == rhs.limit &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.sort == rhs.sort
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(limit)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(sort)
    }
}
