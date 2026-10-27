//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user is unblocked on a call,
/// this can be useful to notify the user that they can now join the call again
public final class UnblockedUserEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
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

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
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
