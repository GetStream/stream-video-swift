//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PublisherAggregateStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var byTrackType: [String: Count]?
    public var total: Count?

    public init(byTrackType: [String: Count]? = nil, total: Count? = nil) {
        self.byTrackType = byTrackType
        self.total = total
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case byTrackType = "by_track_type"
        case total
    }
    
    public static func == (lhs: PublisherAggregateStats, rhs: PublisherAggregateStats) -> Bool {
        lhs.byTrackType == rhs.byTrackType &&
            lhs.total == rhs.total
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(byTrackType)
        hasher.combine(total)
    }
}
