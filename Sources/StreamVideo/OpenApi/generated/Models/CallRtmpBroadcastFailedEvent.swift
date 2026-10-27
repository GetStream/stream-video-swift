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

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case name
        case type
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
