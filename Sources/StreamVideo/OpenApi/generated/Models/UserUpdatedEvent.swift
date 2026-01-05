//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var receivedAt: Date?
    public var type: String = "user.updated"
    public var user: UserEventPayload

    public init(createdAt: Date, receivedAt: Date? = nil, user: UserEventPayload) {
        self.createdAt = createdAt
        self.receivedAt = receivedAt
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case receivedAt = "received_at"
        case type
        case user
    }
    
    public static func == (lhs: UserUpdatedEvent, rhs: UserUpdatedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
