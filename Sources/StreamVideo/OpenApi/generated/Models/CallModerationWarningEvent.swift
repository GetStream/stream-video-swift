//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a moderation warning is issued to a user
public final class CallModerationWarningEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// Custom data associated with the moderation action
    public var custom: [String: RawJSON]
    /// The warning message
    public var message: String
    /// The type of event: "call.moderation_warning" in this case
    public var type: String = "call.moderation_warning"
    /// The user ID who is receiving the warning
    public var userId: String

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], message: String, userId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.message = message
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case message
        case type
        case userId = "user_id"
    }
}

extension CallModerationWarningEvent: Hashable {
    public static func == (lhs: CallModerationWarningEvent, rhs: CallModerationWarningEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.message == rhs.message &&
            lhs.type == rhs.type &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(message)
        hasher.combine(type)
        hasher.combine(userId)
    }
}
