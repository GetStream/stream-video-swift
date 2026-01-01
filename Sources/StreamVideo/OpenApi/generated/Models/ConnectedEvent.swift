//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ConnectedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var connectionId: String
    public var createdAt: Date
    public var me: OwnUserResponse
    public var type: String = "connection.ok"

    public init(connectionId: String, createdAt: Date, me: OwnUserResponse) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case me
        case type
    }
    
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
