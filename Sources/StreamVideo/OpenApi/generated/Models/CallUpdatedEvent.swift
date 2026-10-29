//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call is updated, clients should use this update the local state of the call.
/// This event also contains the capabilities by role for the call, clients should update the own_capability for the current.
public final class CallUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    /// The capabilities by role for this call
    public var capabilitiesByRole: [String: [String]]
    public var createdAt: Date
    /// The type of event: "call.updated" in this case
    public var type: String = "call.updated"

    public init(call: CallResponse, callCid: String, capabilitiesByRole: [String: [String]], createdAt: Date) {
        self.call = call
        self.callCid = callCid
        self.capabilitiesByRole = capabilitiesByRole
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.capabilitiesByRole = try container.decode([String: [String]].self, forKey: .capabilitiesByRole)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(capabilitiesByRole, forKey: .capabilitiesByRole)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
    }
}

extension CallUpdatedEvent: Hashable {
    public static func == (lhs: CallUpdatedEvent, rhs: CallUpdatedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.capabilitiesByRole == rhs.capabilitiesByRole &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(capabilitiesByRole)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
