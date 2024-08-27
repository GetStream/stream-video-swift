//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BlockUsersResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var blockedByUserId: String
    public var blockedUserId: String
    public var createdAt: Date
    public var duration: String

    public init(blockedByUserId: String, blockedUserId: String, createdAt: Date, duration: String) {
        self.blockedByUserId = blockedByUserId
        self.blockedUserId = blockedUserId
        self.createdAt = createdAt
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUserId = "blocked_by_user_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
        case duration
    }
}
