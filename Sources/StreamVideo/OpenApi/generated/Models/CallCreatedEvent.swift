//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call is created. Clients receiving this event should check if the ringing
/// field is set to true and if so, show the call screen
public final class CallCreatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// the members added to this call
    public var members: [MemberResponse]
    /// The type of event: "call.created" in this case
    public var type: String = "call.created"

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

extension CallCreatedEvent: Hashable {
    public static func == (lhs: CallCreatedEvent, rhs: CallCreatedEvent) -> Bool {
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
