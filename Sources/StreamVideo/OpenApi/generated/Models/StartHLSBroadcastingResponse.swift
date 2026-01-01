//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StartHLSBroadcastingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var playlistUrl: String

    public init(duration: String, playlistUrl: String) {
        self.duration = duration
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case playlistUrl = "playlist_url"
    }
    
    public static func == (lhs: StartHLSBroadcastingResponse, rhs: StartHLSBroadcastingResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.playlistUrl == rhs.playlistUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(playlistUrl)
    }
}
