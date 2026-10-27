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

    public enum CodingKeys: String, CodingKey {
        case call
        case callCid = "call_cid"
        case capabilitiesByRole = "capabilities_by_role"
        case createdAt = "created_at"
        case type
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
