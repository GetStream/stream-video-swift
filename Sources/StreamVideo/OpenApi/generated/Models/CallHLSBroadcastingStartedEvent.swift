//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when HLS broadcasting has started
public final class CallHLSBroadcastingStartedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var hlsPlaylistUrl: String
    /// The type of event: "call.hls_broadcasting_started" in this case
    public var type: String = "call.hls_broadcasting_started"

    public init(callCid: String, createdAt: Date, hlsPlaylistUrl: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.hlsPlaylistUrl = hlsPlaylistUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.hlsPlaylistUrl = try container.decode(String.self, forKey: .hlsPlaylistUrl)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallHLSBroadcastingStartedEvent: Hashable {
    public static func == (lhs: CallHLSBroadcastingStartedEvent, rhs: CallHLSBroadcastingStartedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.hlsPlaylistUrl == rhs.hlsPlaylistUrl &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(hlsPlaylistUrl)
        hasher.combine(type)
    }
}
