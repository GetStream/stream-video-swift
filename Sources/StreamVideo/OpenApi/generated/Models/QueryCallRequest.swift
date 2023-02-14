//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct QueryCallRequest: Codable, JSONEncodable, Hashable {

    internal var filterConditions: [String: AnyCodable]?
    internal var limit: Double?
    internal var memberLimit: Double?
    internal var messageLimit: Double?
    internal var next: String?
    internal var prev: String?
    internal var sort: [SortParamRequest]
    internal var watch: Bool?

    internal init(
        filterConditions: [String: AnyCodable]? = nil,
        limit: Double? = nil,
        memberLimit: Double? = nil,
        messageLimit: Double? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest],
        watch: Bool? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.memberLimit = memberLimit
        self.messageLimit = messageLimit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.watch = watch
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case memberLimit = "member_limit"
        case messageLimit = "message_limit"
        case next
        case prev
        case sort
        case watch
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(filterConditions, forKey: .filterConditions)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(memberLimit, forKey: .memberLimit)
        try container.encodeIfPresent(messageLimit, forKey: .messageLimit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encode(sort, forKey: .sort)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}
