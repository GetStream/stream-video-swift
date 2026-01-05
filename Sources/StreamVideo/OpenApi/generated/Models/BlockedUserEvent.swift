//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class BlockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var blockedByUser: UserResponse?
    public var callCid: String
    public var createdAt: Date
    public var type: String = "call.blocked_user"
    public var user: UserResponse

    public init(blockedByUser: UserResponse? = nil, callCid: String, createdAt: Date, user: UserResponse) {
        self.blockedByUser = blockedByUser
        self.callCid = callCid
        self.createdAt = createdAt
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUser = "blocked_by_user"
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }
    
    public static func == (lhs: BlockedUserEvent, rhs: BlockedUserEvent) -> Bool {
        lhs.blockedByUser == rhs.blockedByUser &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockedByUser)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
