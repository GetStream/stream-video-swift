//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call session starts
public final class CallSessionStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// Call session ID
    public var sessionId: String
    /// The type of event: "call.session_started" in this case
    public var type: String = "call.session_started"

    public init(call: CallResponse, callCid: String, createdAt: Date, sessionId: String) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(type, forKey: .type)
    }
}

extension CallSessionStartedEvent: Hashable {
    public static func == (lhs: CallSessionStartedEvent, rhs: CallSessionStartedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
