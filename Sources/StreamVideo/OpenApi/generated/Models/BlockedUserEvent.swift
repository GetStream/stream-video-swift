//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to call participants to notify when a user is blocked on a call, clients can use this event to show a notification.
/// If the user is the current user, the client should leave the call screen as well
public final class BlockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// User response object
    public var blockedByUser: UserResponse?
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.blocked_user" in this case
    public var type: String = "call.blocked_user"
    /// User response object
    public var user: UserResponse

    public init(blockedByUser: UserResponse? = nil, callCid: String, createdAt: Date, user: UserResponse) {
        self.blockedByUser = blockedByUser
        self.callCid = callCid
        self.createdAt = createdAt
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case blockedByUser = "blocked_by_user"
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }
}

extension BlockedUserEvent: Hashable {
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
