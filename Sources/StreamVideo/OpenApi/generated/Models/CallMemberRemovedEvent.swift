//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when one or more members are removed from a call
public final class CallMemberRemovedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// the list of member IDs removed from the call
    public var members: [String]
    /// The type of event: "call.member_removed" in this case
    public var type: String = "call.member_removed"

    public init(call: CallResponse, callCid: String, createdAt: Date, members: [String]) {
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

extension CallMemberRemovedEvent: Hashable {
    public static func == (lhs: CallMemberRemovedEvent, rhs: CallMemberRemovedEvent) -> Bool {
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
