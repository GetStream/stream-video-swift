//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UnblockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var type: String = "call.unblocked_user"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }
    
    public static func == (lhs: UnblockedUserEvent, rhs: UnblockedUserEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
