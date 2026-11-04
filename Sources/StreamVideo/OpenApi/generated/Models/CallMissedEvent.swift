//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to call members who did not accept/reject/join the call to notify they missed the call
public final class CallMissedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// List of members who missed the call
    public var members: [MemberResponse]
    public var notifyUser: Bool
    /// Call session ID
    public var sessionId: String
    /// The type of event: "call.notification" in this case
    public var type: String = "call.missed"
    /// User response object
    public var user: UserResponse

    public init(
        call: CallResponse,
        callCid: String,
        createdAt: Date,
        members: [MemberResponse],
        notifyUser: Bool,
        sessionId: String,
        user: UserResponse
    ) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.notifyUser = notifyUser
        self.sessionId = sessionId
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case notifyUser = "notify_user"
        case sessionId = "session_id"
        case type
        case user
    }
}

extension CallMissedEvent: Hashable {
    public static func == (lhs: CallMissedEvent, rhs: CallMissedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.notifyUser == rhs.notifyUser &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(notifyUser)
        hasher.combine(sessionId)
        hasher.combine(type)
        hasher.combine(user)
    }
}
