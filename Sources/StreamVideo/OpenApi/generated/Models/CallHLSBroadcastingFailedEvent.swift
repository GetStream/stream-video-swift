//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when HLS broadcasting has failed
public final class CallHLSBroadcastingFailedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    /// The type of event: "call.hls_broadcasting_failed" in this case
    public let type: String

    public init(callCid: String, createdAt: Date, type: String = "call.hls_broadcasting_failed") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallHLSBroadcastingFailedEvent: Hashable {
    public static func == (lhs: CallHLSBroadcastingFailedEvent, rhs: CallHLSBroadcastingFailedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
