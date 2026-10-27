//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RequestPermissionRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var permissions: [String]

    public init(permissions: [String]) {
        self.permissions = permissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.permissions = try container.decode([String].self, forKey: .permissions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(permissions, forKey: .permissions)
    }
}

extension RequestPermissionRequest: Hashable {
    public static func == (lhs: RequestPermissionRequest, rhs: RequestPermissionRequest) -> Bool {
        lhs.permissions == rhs.permissions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(permissions)
    }
}
