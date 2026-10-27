//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class HealthCheckEvent: @unchecked Sendable, Event, Codable, JSONEncodable {
    public var cid: String?
    public var connectionId: String
    public var createdAt: Date
    public var receivedAt: Date?
    public var type: String = "health.check"

    public init(cid: String? = nil, connectionId: String, createdAt: Date, receivedAt: Date? = nil) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.receivedAt = receivedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decodeIfPresent(String.self, forKey: .cid)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.receivedAt = try container.decodeIfPresent(Date.self, forKey: .receivedAt)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(receivedAt, forKey: .receivedAt)
        try container.encode(type, forKey: .type)
    }
}

extension HealthCheckEvent: Hashable {
    public static func == (lhs: HealthCheckEvent, rhs: HealthCheckEvent) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.connectionId == rhs.connectionId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(connectionId)
        hasher.combine(createdAt)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
