//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RequestPermissionRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var permissions: [String]

    public init(permissions: [String]) {
        self.permissions = permissions
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
