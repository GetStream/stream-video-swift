//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a moderation blur action is applied to a user's video stream
public final class CallModerationBlurEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    /// Custom data associated with the moderation action
    public let custom: [String: RawJSON]
    /// The type of event: "call.moderation_blur" in this case
    public let type: String
    /// The user ID whose video stream is being blurred
    public let userId: String

    public init(
        callCid: String,
        createdAt: Date,
        custom: [String: RawJSON],
        type: String = "call.moderation_blur",
        userId: String
    ) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.type = type
        self.userId = userId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.type = try container.decode(String.self, forKey: .type)
        self.userId = try container.decode(String.self, forKey: .userId)
    }
}

extension CallModerationBlurEvent: Hashable {
    public static func == (lhs: CallModerationBlurEvent, rhs: CallModerationBlurEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.type == rhs.type &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(type)
        hasher.combine(userId)
    }
}
