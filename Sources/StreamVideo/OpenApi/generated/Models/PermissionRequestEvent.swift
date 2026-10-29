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

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case permissions
        case type
        case user
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
