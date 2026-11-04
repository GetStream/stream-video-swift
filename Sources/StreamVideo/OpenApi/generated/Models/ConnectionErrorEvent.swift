//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the WS connection fails
public final class ConnectionErrorEvent: @unchecked Sendable, Event, Decodable {
    public var connectionId: String
    public var createdAt: Date
    public var error: APIError
    /// The type of event: "connection.error" in this case
    public var type: String = "connection.error"

    public init(connectionId: String, createdAt: Date, error: APIError) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.error = try container.decode(APIError.self, forKey: .error)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension ConnectionErrorEvent: Hashable {
    public static func == (lhs: ConnectionErrorEvent, rhs: ConnectionErrorEvent) -> Bool {
        lhs.connectionId == rhs.connectionId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.error == rhs.error &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(connectionId)
        hasher.combine(createdAt)
        hasher.combine(error)
        hasher.combine(type)
    }
}
