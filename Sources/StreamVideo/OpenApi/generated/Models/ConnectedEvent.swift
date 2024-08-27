//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ConnectedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var connectionId: String
    public var createdAt: Date
    public var me: OwnUserResponse
    public var type: String

    public init(connectionId: String, createdAt: Date, me: OwnUserResponse, type: String) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case me
        case type
    }
}
