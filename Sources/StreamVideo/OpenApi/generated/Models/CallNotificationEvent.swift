//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to all call members to notify they are getting called
public final class CallNotificationEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
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
