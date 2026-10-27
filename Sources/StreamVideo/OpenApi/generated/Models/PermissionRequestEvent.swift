//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user requests access to a feature on a call,
/// clients receiving this event should display a permission request to the user
public final class PermissionRequestEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// The list of permissions requested by the user
    public var permissions: [String]
    /// The type of event: "call.permission_request" in this case
    public var type: String = "call.permission_request"
    /// User response object
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, permissions: [String], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.permissions = permissions
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.permissions = try container.decode([String].self, forKey: .permissions)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

extension PermissionRequestEvent: Hashable {
    public static func == (lhs: PermissionRequestEvent, rhs: PermissionRequestEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.permissions == rhs.permissions &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(permissions)
        hasher.combine(type)
        hasher.combine(user)
    }
}
