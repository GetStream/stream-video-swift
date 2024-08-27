//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallUserMutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var fromUserId: String
    public var mutedUserIds: [String]
    public var type: String

    public init(callCid: String, createdAt: Date, fromUserId: String, mutedUserIds: [String], type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.fromUserId = fromUserId
        self.mutedUserIds = mutedUserIds
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case fromUserId = "from_user_id"
        case mutedUserIds = "muted_user_ids"
        case type
    }
}
