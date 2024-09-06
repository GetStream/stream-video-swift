//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserMuteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
