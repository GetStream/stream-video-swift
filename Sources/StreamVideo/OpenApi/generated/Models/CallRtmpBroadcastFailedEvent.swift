//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call RTMP broadcast has failed
public final class CallRtmpBroadcastFailedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// The unique identifier for a call (<type>:<id>)
    public var callCid: String
    /// Date/time of creation
    public var createdAt: Date
    /// Name of the given RTMP broadcast
    public var name: String
    /// The type of event: "call.rtmp_broadcast_failed" in this case
    public var type: String = "call.rtmp_broadcast_failed"

    public init(callCid: String, createdAt: Date, name: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
    }
}

extension CallRtmpBroadcastFailedEvent: Hashable {
    public static func == (lhs: CallRtmpBroadcastFailedEvent, rhs: CallRtmpBroadcastFailedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.name == rhs.name &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(name)
        hasher.combine(type)
    }
}
