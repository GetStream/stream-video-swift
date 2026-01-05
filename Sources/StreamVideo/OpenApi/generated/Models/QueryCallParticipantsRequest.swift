//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryCallParticipantsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var filterConditions: [String: RawJSON]?

    public init(filterConditions: [String: RawJSON]? = nil) {
        self.filterConditions = filterConditions
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case filterConditions = "filter_conditions"
}

    public static func == (lhs: QueryCallParticipantsRequest, rhs: QueryCallParticipantsRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
    }
}
