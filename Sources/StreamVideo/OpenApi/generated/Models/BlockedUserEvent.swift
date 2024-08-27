//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BlockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var blockedByUser: UserResponse? = nil
    public var callCid: String
    public var createdAt: Date
    public var type: String
    public var user: UserResponse

    public init(blockedByUser: UserResponse? = nil, callCid: String, createdAt: Date, type: String, user: UserResponse) {
        self.blockedByUser = blockedByUser
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUser = "blocked_by_user"
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }
}
