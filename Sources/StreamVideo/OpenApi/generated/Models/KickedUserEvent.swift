//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent to call participants to notify when a user is kicked from a call. Clients should make the kicked user leave the call UI.
public final class KickedUserEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// User response object
    public var kickedByUser: UserResponse?
    /// The type of event: "call.kicked_user" in this case
    public var type: String = "call.kicked_user"
    /// User response object
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, kickedByUser: UserResponse? = nil, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.kickedByUser = kickedByUser
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.kickedByUser = try container.decodeIfPresent(UserResponse.self, forKey: .kickedByUser)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }
}

extension KickedUserEvent: Hashable {
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
