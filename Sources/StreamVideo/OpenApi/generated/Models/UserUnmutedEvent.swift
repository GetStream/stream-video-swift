//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class UserUnmutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var targetUser: String?
    public var targetUsers: [String]?
    public var type: String
    public var user: UserObject?

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
    
    public static func == (lhs: UserUnmutedEvent, rhs: UserUnmutedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.targetUser == rhs.targetUser &&
            lhs.targetUsers == rhs.targetUsers &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(targetUser)
        hasher.combine(targetUsers)
        hasher.combine(type)
        hasher.combine(user)
    }
}
