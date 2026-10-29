//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when one or more members are removed from a call
public final class CallMemberRemovedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decode([String].self, forKey: .members)
        self.type = try container.decode(String.self, forKey: .type)
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
