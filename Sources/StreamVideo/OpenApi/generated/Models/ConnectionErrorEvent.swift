//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ConnectionErrorEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var connectionId: String
    public var createdAt: Date
    public var error: APIError
    public var type: String

    public init(connectionId: String, createdAt: Date, error: APIError, type: String) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.error = error
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case error
        case type
    }
}
