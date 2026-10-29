//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user is unblocked on a call,
/// this can be useful to notify the user that they can now join the call again
public final class UnblockedUserEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.unblocked_user" in this case
    public var type: String = "call.unblocked_user"
    /// User response object
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }
}

extension UnblockedUserEvent: Hashable {
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
