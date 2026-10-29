//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a moderation warning is issued to a user
public final class CallModerationWarningEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.message = try container.decode(String.self, forKey: .message)
        self.type = try container.decode(String.self, forKey: .type)
        self.userId = try container.decode(String.self, forKey: .userId)
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
