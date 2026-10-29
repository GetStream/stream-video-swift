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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(members, forKey: .members)
        try container.encode(type, forKey: .type)
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
