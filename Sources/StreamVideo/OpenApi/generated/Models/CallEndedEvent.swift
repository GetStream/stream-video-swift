//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call is mark as ended for all its participants. Clients receiving this event should leave the call screen
public final class CallEndedEvent: Sendable, Event, Decodable, WSCallEvent {
    /// Represents a call
    public let call: CallResponse
    public let callCid: String
    public let createdAt: Date
    /// The list of members in the call
    public let members: [MemberResponse]?
    /// The reason why the call ended, if available
    public let reason: String?
    /// The type of event: "call.ended" in this case
    public let type: String
    /// User response object
    public let user: UserResponse?

    public init(
        call: CallResponse,
        callCid: String,
        createdAt: Date,
        members: [MemberResponse]? = nil,
        reason: String? = nil,
        type: String = "call.ended",
        user: UserResponse? = nil
    ) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.reason = reason
        self.type = type
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decodeIfPresent([MemberResponse].self, forKey: .members)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserResponse.self, forKey: .user)
    }
}

extension CallEndedEvent: Hashable {
    public static func == (lhs: CallEndedEvent, rhs: CallEndedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.reason == rhs.reason &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(reason)
        hasher.combine(type)
        hasher.combine(user)
    }
}
