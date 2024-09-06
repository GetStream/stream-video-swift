//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryCallsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]?
    public var limit: Int?
    public var next: String?
    public var prev: String?
    public var sort: [SortParamRequest?]?
    public var watch: Bool?

    public init(
        filterConditions: [String: RawJSON]? = nil,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest?]? = nil,
        watch: Bool? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case next
        case prev
        case sort
        case watch
    }
}
