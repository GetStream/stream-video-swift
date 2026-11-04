//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when one or more members are updated
public final class CallMemberUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// The list of members that were updated
    public var members: [MemberResponse]
    /// The type of event: "call.member_updated" in this case
    public var type: String = "call.member_updated"

    public init(call: CallResponse, callCid: String, createdAt: Date, members: [MemberResponse]) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
    }

    public enum CodingKeys: String, CodingKey {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case type
    }
}

extension CallMemberUpdatedEvent: Hashable {
    public static func == (lhs: CallMemberUpdatedEvent, rhs: CallMemberUpdatedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(type)
    }
}
