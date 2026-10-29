//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallParticipantsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    public var filterConditions: [String: RawJSON]?

    public init(filterConditions: [String: RawJSON]? = nil) {
        self.filterConditions = filterConditions
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
