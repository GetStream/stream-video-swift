//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryCallStatsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]?
    public var limit: Int?
    public var next: String?
    public var prev: String?
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case next
        case prev
        case sort
    }
    
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
