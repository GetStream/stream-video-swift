//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to call members who did not accept/reject/join the call to notify they missed the call
public final class CallMissedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.notifyUser = try container.decode(Bool.self, forKey: .notifyUser)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
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
