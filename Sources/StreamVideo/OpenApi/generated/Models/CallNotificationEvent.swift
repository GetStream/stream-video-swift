//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to all call members to notify they are getting called
public final class CallNotificationEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// Call members
    public var members: [MemberResponse]
    /// Call session ID
    public var sessionId: String
    /// The type of event: "call.notification" in this case
    public var type: String = "call.notification"
    /// User response object
    public var user: UserResponse

    public init(
        call: CallResponse,
        callCid: String,
        createdAt: Date,
        members: [MemberResponse],
        sessionId: String,
        user: UserResponse
    ) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.sessionId = sessionId
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case sessionId = "session_id"
        case type
        case user
    }
}

extension CallNotificationEvent: Hashable {
    public static func == (lhs: CallNotificationEvent, rhs: CallNotificationEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(sessionId)
        hasher.combine(type)
        hasher.combine(user)
    }
}
