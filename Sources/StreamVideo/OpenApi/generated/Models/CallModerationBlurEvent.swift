//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallModerationBlurEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var type: String = "call.moderation_blur"
    public var userId: String

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], userId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case type
        case userId = "user_id"
    }

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
