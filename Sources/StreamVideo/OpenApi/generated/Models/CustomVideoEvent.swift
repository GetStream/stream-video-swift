//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CustomVideoEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var type: String = "custom"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case type
        case user
    }
    
    public static func == (lhs: CustomVideoEvent, rhs: CustomVideoEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(type)
        hasher.combine(user)
    }
}
