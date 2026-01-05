//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PermissionRequestEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var permissions: [String]
    public var type: String = "call.permission_request"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, permissions: [String], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.permissions = permissions
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case permissions
        case type
        case user
    }
    
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
