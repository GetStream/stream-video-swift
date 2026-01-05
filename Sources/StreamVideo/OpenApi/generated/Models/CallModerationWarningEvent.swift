//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallModerationWarningEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var message: String
    public var type: String = "call.moderation_warning"
    public var userId: String

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], message: String, userId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.message = message
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case message
        case type
        case userId = "user_id"
    }

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
