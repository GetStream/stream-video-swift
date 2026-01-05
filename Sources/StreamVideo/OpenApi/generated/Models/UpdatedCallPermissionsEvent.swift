//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UpdatedCallPermissionsEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var ownCapabilities: [OwnCapability]
    public var type: String = "call.permissions_updated"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, ownCapabilities: [OwnCapability], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case ownCapabilities = "own_capabilities"
        case type
        case user
    }
    
    public static func == (lhs: UpdatedCallPermissionsEvent, rhs: UpdatedCallPermissionsEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.ownCapabilities == rhs.ownCapabilities &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(ownCapabilities)
        hasher.combine(type)
        hasher.combine(user)
    }
}
