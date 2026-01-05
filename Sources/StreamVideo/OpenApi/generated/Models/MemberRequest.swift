//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class MemberRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: MemberRequest, rhs: MemberRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.role == rhs.role &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(role)
        hasher.combine(userId)
    }
}
