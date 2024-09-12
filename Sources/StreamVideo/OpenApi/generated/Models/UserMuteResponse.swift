//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class UserMuteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var expires: Date?
    public var target: UserResponse?
    public var updatedAt: Date
    public var user: UserResponse?

    public init(createdAt: Date, expires: Date? = nil, target: UserResponse? = nil, updatedAt: Date, user: UserResponse? = nil) {
        self.createdAt = createdAt
        self.expires = expires
        self.target = target
        self.updatedAt = updatedAt
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case expires
        case target
        case updatedAt = "updated_at"
        case user
    }
    
    public static func == (lhs: UserMuteResponse, rhs: UserMuteResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.expires == rhs.expires &&
            lhs.target == rhs.target &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(expires)
        hasher.combine(target)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
