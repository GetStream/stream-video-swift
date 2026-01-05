//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class HealthCheckEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case receivedAt = "received_at"
        case type
    }
    
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
