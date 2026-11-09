//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when RTMP broadcast has stopped
public final class CallRtmpBroadcastStoppedEvent: Sendable, Event, Decodable, WSCallEvent {
    /// The unique identifier for a call (<type>:<id>)
    public let callCid: String
    /// Date/time of creation
    public let createdAt: Date
    /// Name of the given RTMP broadcast
    public let name: String
    /// The type of event: "call.rtmp_broadcast_stopped" in this case
    public let type: String

    public init(callCid: String, createdAt: Date, name: String, type: String = "call.rtmp_broadcast_stopped") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallRtmpBroadcastStoppedEvent: Hashable {
    public static func == (lhs: CallRtmpBroadcastStoppedEvent, rhs: CallRtmpBroadcastStoppedEvent) -> Bool {
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
