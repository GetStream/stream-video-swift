//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Emitted when app settings are updated
public final class AppUpdatedEvent: @unchecked Sendable, Event, Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.app = try container.decode(AppEventResponse.self, forKey: .app)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.receivedAt = try container.decodeIfPresent(Date.self, forKey: .receivedAt)
        self.type = try container.decode(String.self, forKey: .type)
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
