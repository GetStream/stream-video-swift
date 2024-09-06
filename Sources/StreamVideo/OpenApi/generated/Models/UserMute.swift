//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserMute: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var expires: Date?
    public var target: UserObject?
    public var updatedAt: Date
    public var user: UserObject?

    public init(createdAt: Date, expires: Date? = nil, target: UserObject? = nil, updatedAt: Date, user: UserObject? = nil) {
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
