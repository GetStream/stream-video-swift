//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct HealthCheckEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var cid: String
    public var connectionId: String
    public var createdAt: Date
    public var type: String

    public init(cid: String, connectionId: String, createdAt: Date, type: String) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case type
    }
}
