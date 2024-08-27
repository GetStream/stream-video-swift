//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallHLSBroadcastingStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var hlsPlaylistUrl: String
    public var type: String

    public init(callCid: String, createdAt: Date, hlsPlaylistUrl: String, type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.hlsPlaylistUrl = hlsPlaylistUrl
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case hlsPlaylistUrl = "hls_playlist_url"
        case type
    }
}
