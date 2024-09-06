//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MemberRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?
    public var role: String?
    public var userId: String

    public init(custom: [String: RawJSON]? = nil, role: String? = nil, userId: String) {
        self.custom = custom
        self.role = role
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case role
        case userId = "user_id"
    }
}
