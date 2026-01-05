//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallUserMutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var fromUserId: String
    public var mutedUserIds: [String]
    public var type: String = "call.user_muted"

    public init(callCid: String, createdAt: Date, fromUserId: String, mutedUserIds: [String]) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.fromUserId = fromUserId
        self.mutedUserIds = mutedUserIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case fromUserId = "from_user_id"
        case mutedUserIds = "muted_user_ids"
        case type
    }
    
    public static func == (lhs: CallUserMutedEvent, rhs: CallUserMutedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.fromUserId == rhs.fromUserId &&
            lhs.mutedUserIds == rhs.mutedUserIds &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(fromUserId)
        hasher.combine(mutedUserIds)
        hasher.combine(type)
    }
}
