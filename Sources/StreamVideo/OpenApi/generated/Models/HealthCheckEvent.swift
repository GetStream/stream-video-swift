//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class HealthCheckEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var cid: String?
    public var connectionId: String
    public var createdAt: Date
    public var me: OwnUserResponse?
    public var receivedAt: Date?
    public var type: String = "health.check"

    public init(cid: String? = nil, connectionId: String, createdAt: Date, me: OwnUserResponse? = nil, receivedAt: Date? = nil) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
        self.receivedAt = receivedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case me
        case receivedAt = "received_at"
        case type
    }
    
    public static func == (lhs: HealthCheckEvent, rhs: HealthCheckEvent) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.connectionId == rhs.connectionId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.me == rhs.me &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(connectionId)
        hasher.combine(createdAt)
        hasher.combine(me)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
