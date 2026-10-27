//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallsRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Filter conditions to apply to the query
    public var filterConditions: [String: RawJSON]?
    public var limit: Int?
    public var next: String?
    public var prev: String?
    /// Array of sort parameters
    public var sort: [SortParamRequest]?
    public var watch: Bool?

    public init(
        filterConditions: [String: RawJSON]? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest]? = nil,
        watch: Bool? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.watch = watch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.filterConditions = try container.decodeIfPresent([String: RawJSON].self, forKey: .filterConditions)
        self.limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
        self.sort = try container.decodeIfPresent([SortParamRequest].self, forKey: .sort)
        self.watch = try container.decodeIfPresent(Bool.self, forKey: .watch)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(filterConditions, forKey: .filterConditions)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}

extension QueryCallsRequest: Hashable {
    public static func == (lhs: QueryCallsRequest, rhs: QueryCallsRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.limit == rhs.limit &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.sort == rhs.sort &&
            lhs.watch == rhs.watch
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(limit)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(sort)
        hasher.combine(watch)
    }
}
