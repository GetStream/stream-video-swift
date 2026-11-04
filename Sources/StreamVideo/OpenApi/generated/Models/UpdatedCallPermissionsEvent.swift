//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to notify about permission changes for a user, clients receiving this event should update their UI accordingly
public final class UpdatedCallPermissionsEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// The capabilities of the current user
    public var ownCapabilities: [OwnCapability]
    /// The type of event: "call.permissions_updated" in this case
    public var type: String = "call.permissions_updated"
    /// User response object
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, ownCapabilities: [OwnCapability], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

extension UpdatedCallPermissionsEvent: Hashable {
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
