//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserDeactivatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var createdBy: UserObject
    public var type: String
    public var user: UserObject? = nil

    public init(createdAt: Date, createdBy: UserObject, type: String, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdBy = "created_by"
        case type
        case user
    }
}
