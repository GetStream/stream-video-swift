//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ConnectionErrorEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var connectionId: String
    public var createdAt: Date
    public var error: APIError
    public var type: String = "connection.error"

    public init(connectionId: String, createdAt: Date, error: APIError) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.error = error
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case error
        case type
    }
    
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
