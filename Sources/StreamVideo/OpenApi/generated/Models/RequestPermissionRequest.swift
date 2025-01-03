//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RequestPermissionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var permissions: [String]

    public init(permissions: [String]) {
        self.permissions = permissions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case permissions
    }
    
    public static func == (lhs: RequestPermissionRequest, rhs: RequestPermissionRequest) -> Bool {
        lhs.permissions == rhs.permissions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(permissions)
    }
}
