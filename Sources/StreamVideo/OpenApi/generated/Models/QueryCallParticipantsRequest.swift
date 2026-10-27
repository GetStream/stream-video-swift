//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallParticipantsRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Filter conditions to apply to the query
    public var filterConditions: [String: RawJSON]?

    public init(filterConditions: [String: RawJSON]? = nil) {
        self.filterConditions = filterConditions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.filterConditions = try container.decodeIfPresent([String: RawJSON].self, forKey: .filterConditions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(filterConditions, forKey: .filterConditions)
    }
}

extension QueryCallParticipantsRequest: Hashable {
    public static func == (lhs: QueryCallParticipantsRequest, rhs: QueryCallParticipantsRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
    }
}
