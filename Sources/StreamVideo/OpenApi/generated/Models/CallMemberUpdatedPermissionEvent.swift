//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallMemberUpdatedPermissionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var capabilitiesByRole: [String: [String]]
    public var createdAt: Date
    public var members: [MemberResponse]
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case capabilitiesByRole = "capabilities_by_role"
        case createdAt = "created_at"
        case members
        case type
    }
    
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
