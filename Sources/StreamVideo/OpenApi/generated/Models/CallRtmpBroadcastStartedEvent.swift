//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when RTMP broadcast has started
public final class CallRtmpBroadcastStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// The unique identifier for a call (<type>:<id>)
    public var callCid: String
    /// Date/time of creation
    public var createdAt: Date
    /// Name of the given RTMP broadcast
    public var name: String
    /// The type of event: "call.rtmp_broadcast_started" in this case
    public var type: String = "call.rtmp_broadcast_started"

    public init(callCid: String, createdAt: Date, name: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case name
        case type
    }
}

extension CallRtmpBroadcastStartedEvent: Hashable {
    public static func == (lhs: CallRtmpBroadcastStartedEvent, rhs: CallRtmpBroadcastStartedEvent) -> Bool {
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
