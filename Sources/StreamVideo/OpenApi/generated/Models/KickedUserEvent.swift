//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class KickedUserEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var kickedByUser: UserResponse?
    public var type: String = "call.kicked_user"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, kickedByUser: UserResponse? = nil, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.kickedByUser = kickedByUser
        self.user = user
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case callCid = "call_cid"
    case createdAt = "created_at"
    case kickedByUser = "kicked_by_user"
    case type
    case user
}

    public static func == (lhs: KickedUserEvent, rhs: KickedUserEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
        lhs.createdAt == rhs.createdAt &&
        lhs.kickedByUser == rhs.kickedByUser &&
        lhs.type == rhs.type &&
        lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(kickedByUser)
        hasher.combine(type)
        hasher.combine(user)
    }
}
