//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var receivedAt: Date?
    public var type: String
    public var user: UserEventPayload

    public init(createdAt: Date, receivedAt: Date? = nil, type: String, user: UserEventPayload) {
        self.createdAt = createdAt
        self.receivedAt = receivedAt
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case receivedAt = "received_at"
        case type
        case user
    }
}
