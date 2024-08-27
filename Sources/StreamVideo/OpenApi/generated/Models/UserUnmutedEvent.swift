//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserUnmutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var targetUser: String? = nil
    public var targetUsers: [String]? = nil
    public var type: String
    public var user: UserObject? = nil

    public init(createdAt: Date, targetUser: String? = nil, targetUsers: [String]? = nil, type: String, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.targetUser = targetUser
        self.targetUsers = targetUsers
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case targetUser = "target_user"
        case targetUsers = "target_users"
        case type
        case user
    }
}
