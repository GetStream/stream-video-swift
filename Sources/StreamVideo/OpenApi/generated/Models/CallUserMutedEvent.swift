//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call member is muted
public final class CallUserMutedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var fromUserId: String
    public var mutedUserIds: [String]
    public var reason: String
    /// The type of event: "call.user_muted" in this case
    public var type: String = "call.user_muted"

    public init(callCid: String, createdAt: Date, fromUserId: String, mutedUserIds: [String], reason: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.fromUserId = fromUserId
        self.mutedUserIds = mutedUserIds
        self.reason = reason
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.fromUserId = try container.decode(String.self, forKey: .fromUserId)
        self.mutedUserIds = try container.decode([String].self, forKey: .mutedUserIds)
        self.reason = try container.decode(String.self, forKey: .reason)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallUserMutedEvent: Hashable {
    public static func == (lhs: CallUserMutedEvent, rhs: CallUserMutedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.fromUserId == rhs.fromUserId &&
            lhs.mutedUserIds == rhs.mutedUserIds &&
            lhs.reason == rhs.reason &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(fromUserId)
        hasher.combine(mutedUserIds)
        hasher.combine(reason)
        hasher.combine(type)
    }
}
