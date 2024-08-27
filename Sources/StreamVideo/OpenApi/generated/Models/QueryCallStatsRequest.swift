//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryCallStatsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]? = nil
    public var limit: Int? = nil
    public var next: String? = nil
    public var prev: String? = nil
    public var sort: [SortParamRequest?]? = nil

    public init(
        filterConditions: [String: RawJSON]? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest?]? = nil
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
}
