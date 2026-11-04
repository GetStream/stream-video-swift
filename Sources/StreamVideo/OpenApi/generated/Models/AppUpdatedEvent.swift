//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Emitted when app settings are updated
public final class AppUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable {
    public var app: AppEventResponse
    /// Date/time of creation
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var receivedAt: Date?
    /// The type of event: "app.updated" in this case
    public var type: String = "app.updated"

    public init(app: AppEventResponse, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil) {
        self.app = app
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
    }

    public enum CodingKeys: String, CodingKey {
        case app
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
    }
}

extension AppUpdatedEvent: Hashable {
    public static func == (lhs: AppUpdatedEvent, rhs: AppUpdatedEvent) -> Bool {
        lhs.app == rhs.app &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(app)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
