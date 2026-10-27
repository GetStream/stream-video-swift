//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user gets updated. The event contains information about the updated user.
public final class UserUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable {
    /// Date/time of creation
    public var createdAt: Date
    public var receivedAt: Date?
    /// The type of event: "user.updated" in this case
    public var type: String = "user.updated"
    public var user: UserEventPayload

    public init(createdAt: Date, receivedAt: Date? = nil, user: UserEventPayload) {
        self.createdAt = createdAt
        self.receivedAt = receivedAt
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case receivedAt = "received_at"
        case type
        case user
    }
}

extension UserUpdatedEvent: Hashable {
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
