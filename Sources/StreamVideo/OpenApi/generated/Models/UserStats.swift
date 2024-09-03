//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var info: UserInfoResponse
    public var minEventTs: Int
    public var rating: Int? = nil
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
}
