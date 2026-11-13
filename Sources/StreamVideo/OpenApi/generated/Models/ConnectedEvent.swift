//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the WS connection is established and authenticated, this event contains the full user object as it is stored on the server
public final class ConnectedEvent: Sendable, Event, Decodable {
    /// The connection_id for this client
    public let connectionId: String
    public let createdAt: Date
    public let me: OwnUserResponse
    /// The type of event: "connection.ok" in this case
    public let type: String

    public init(connectionId: String, createdAt: Date, me: OwnUserResponse, type: String = "connection.ok") {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.me = try container.decode(OwnUserResponse.self, forKey: .me)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension ConnectedEvent: Hashable {
    public static func == (lhs: ConnectedEvent, rhs: ConnectedEvent) -> Bool {
        lhs.connectionId == rhs.connectionId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.me == rhs.me &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(connectionId)
        hasher.combine(createdAt)
        hasher.combine(me)
        hasher.combine(type)
    }
}
