//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class UnblockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var type: String
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }
    
    public static func == (lhs: UnblockedUserEvent, rhs: UnblockedUserEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
