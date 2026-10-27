//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when one or more members get its role updated
public final class CallMemberUpdatedPermissionEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    /// The capabilities by role for this call
    public var capabilitiesByRole: [String: [String]]
    public var createdAt: Date
    /// The list of members that were updated
    public var members: [MemberResponse]
    /// The type of event: "call.member_added" in this case
    public var type: String = "call.member_updated_permission"

    public init(
        call: CallResponse,
        callCid: String,
        capabilitiesByRole: [String: [String]],
        createdAt: Date,
        members: [MemberResponse]
    ) {
        self.call = call
        self.callCid = callCid
        self.capabilitiesByRole = capabilitiesByRole
        self.createdAt = createdAt
        self.members = members
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.capabilitiesByRole = try container.decode([String: [String]].self, forKey: .capabilitiesByRole)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallMemberUpdatedPermissionEvent: Hashable {
    public static func == (lhs: CallMemberUpdatedPermissionEvent, rhs: CallMemberUpdatedPermissionEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.capabilitiesByRole == rhs.capabilitiesByRole &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(capabilitiesByRole)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(type)
    }
}
