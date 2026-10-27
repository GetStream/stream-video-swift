//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user rejects a notification to join a call.
public final class CallRejectedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// Provides information about why the call was rejected. You can provide any value, but the Stream API and SDKs use these default values: rejected, cancel, timeout and busy
    public var reason: String?
    /// The type of event: "call.rejected" in this case
    public var type: String = "call.rejected"
    /// User response object
    public var user: UserResponse

    public init(call: CallResponse, callCid: String, createdAt: Date, reason: String? = nil, user: UserResponse) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.reason = reason
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

extension CallRejectedEvent: Hashable {
    public static func == (lhs: CallRejectedEvent, rhs: CallRejectedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.reason == rhs.reason &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(reason)
        hasher.combine(type)
        hasher.combine(user)
    }
}
