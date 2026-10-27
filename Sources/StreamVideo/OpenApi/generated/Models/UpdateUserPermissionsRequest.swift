//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class UpdateUserPermissionsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var grantPermissions: [String]?
    public var revokePermissions: [String]?
    public var userId: String

    public init(grantPermissions: [String]? = nil, revokePermissions: [String]? = nil, userId: String) {
        self.grantPermissions = grantPermissions
        self.revokePermissions = revokePermissions
        self.userId = userId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(grantPermissions, forKey: .grantPermissions)
        try container.encodeIfPresent(revokePermissions, forKey: .revokePermissions)
        try container.encode(userId, forKey: .userId)
    }
}

extension UpdateUserPermissionsRequest: Hashable {
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
