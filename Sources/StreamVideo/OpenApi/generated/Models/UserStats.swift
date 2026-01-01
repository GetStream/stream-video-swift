//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var info: UserInfoResponse
    public var minEventTs: Int
    public var rating: Int?
    public var sessionStats: [UserSessionStats]

    public init(info: UserInfoResponse, minEventTs: Int, rating: Int? = nil, sessionStats: [UserSessionStats]) {
        self.info = info
        self.minEventTs = minEventTs
        self.rating = rating
        self.sessionStats = sessionStats
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case info
        case minEventTs = "min_event_ts"
        case rating
        case sessionStats = "session_stats"
    }
    
    public static func == (lhs: UserStats, rhs: UserStats) -> Bool {
        lhs.info == rhs.info &&
            lhs.minEventTs == rhs.minEventTs &&
            lhs.rating == rhs.rating &&
            lhs.sessionStats == rhs.sessionStats
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(info)
        hasher.combine(minEventTs)
        hasher.combine(rating)
        hasher.combine(sessionStats)
    }
}
