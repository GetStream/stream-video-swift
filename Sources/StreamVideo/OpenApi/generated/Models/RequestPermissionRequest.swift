//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RequestPermissionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var permissions: [String]

    public init(permissions: [String]) {
        self.permissions = permissions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case permissions
    }
}
