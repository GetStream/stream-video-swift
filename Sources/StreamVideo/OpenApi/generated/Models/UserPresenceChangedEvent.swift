//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class UserPresenceChangedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var type: String
    public var user: UserObject?

    public init(createdAt: Date, type: String, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case user
    }
    
    public static func == (lhs: UserPresenceChangedEvent, rhs: UserPresenceChangedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
