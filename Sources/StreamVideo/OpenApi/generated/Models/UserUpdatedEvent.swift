//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user gets updated. The event contains information about the updated user.
public final class UserUpdatedEvent: @unchecked Sendable, Event, Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.receivedAt = try container.decodeIfPresent(Date.self, forKey: .receivedAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserEventPayload.self, forKey: .user)
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
