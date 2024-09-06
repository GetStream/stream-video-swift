//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryMembersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]?
    public var id: String
    public var limit: Int?
    public var next: String?
    public var prev: String?
    public var sort: [SortParamRequest?]?
    public var type: String

    public init(
        filterConditions: [String: RawJSON]? = nil,
        id: String,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest?]? = nil,
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
}
