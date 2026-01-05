//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UpdateUserPermissionsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var grantPermissions: [String]?
    public var revokePermissions: [String]?
    public var userId: String

    public init(grantPermissions: [String]? = nil, revokePermissions: [String]? = nil, userId: String) {
        self.grantPermissions = grantPermissions
        self.revokePermissions = revokePermissions
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case grantPermissions = "grant_permissions"
        case revokePermissions = "revoke_permissions"
        case userId = "user_id"
    }
    
    public static func == (lhs: UpdateUserPermissionsRequest, rhs: UpdateUserPermissionsRequest) -> Bool {
        lhs.grantPermissions == rhs.grantPermissions &&
            lhs.revokePermissions == rhs.revokePermissions &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(grantPermissions)
        hasher.combine(revokePermissions)
        hasher.combine(userId)
    }
}
