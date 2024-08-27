//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateUserPermissionsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var grantPermissions: [String]? = nil
    public var revokePermissions: [String]? = nil
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
}
