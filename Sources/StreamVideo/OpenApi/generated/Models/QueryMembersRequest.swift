//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryMembersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]?
    public var id: String
    public var limit: Int?
    public var next: String?
    public var prev: String?
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case id
        case limit
        case next
        case prev
        case sort
        case type
    }
    
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
