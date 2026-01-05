//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallHLSBroadcastingStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var hlsPlaylistUrl: String
    public var type: String = "call.hls_broadcasting_started"

    public init(callCid: String, createdAt: Date, hlsPlaylistUrl: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.hlsPlaylistUrl = hlsPlaylistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case hlsPlaylistUrl = "hls_playlist_url"
        case type
    }
    
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
