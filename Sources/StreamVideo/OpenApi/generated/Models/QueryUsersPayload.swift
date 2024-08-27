//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryUsersPayload: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var filterConditions: [String: RawJSON]
    public var includeDeactivatedUsers: Bool? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil
    public var presence: Bool? = nil
    public var sort: [SortParamRequest?]? = nil

    public init(
        filterConditions: [String: RawJSON],
        includeDeactivatedUsers: Bool? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        presence: Bool? = nil,
        sort: [SortParamRequest?]? = nil
    ) {
        self.filterConditions = filterConditions
        self.includeDeactivatedUsers = includeDeactivatedUsers
        self.limit = limit
        self.offset = offset
        self.presence = presence
        self.sort = sort
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case includeDeactivatedUsers = "include_deactivated_users"
        case limit
        case offset
        case presence
        case sort
    }
}
