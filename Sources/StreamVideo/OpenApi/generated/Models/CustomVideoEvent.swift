//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A custom event, this event is used to send custom events to other participants in the call.
public final class CustomVideoEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// Custom data for this object
    public var custom: [String: RawJSON]
    /// The type of event, "custom" in this case
    public var type: String = "custom"
    /// User response object
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case type
        case user
    }
}

extension CustomVideoEvent: Hashable {
    public static func == (lhs: CustomVideoEvent, rhs: CustomVideoEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(type)
        hasher.combine(user)
    }
}
