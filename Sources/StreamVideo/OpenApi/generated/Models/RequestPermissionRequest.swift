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

    public enum CodingKeys: String, CodingKey {
        case permissions
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
