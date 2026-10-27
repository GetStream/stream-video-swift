//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StartHLSBroadcastingResponse is the payload for starting an HLS broadcasting.
public final class StartHLSBroadcastingResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var duration: String
    /// the URL of the HLS playlist
    public var playlistUrl: String

    public init(duration: String, playlistUrl: String) {
        self.duration = duration
        self.playlistUrl = playlistUrl
    }

    public enum CodingKeys: String, CodingKey {
        case duration
        case playlistUrl = "playlist_url"
    }
}

extension StartHLSBroadcastingResponse: Hashable {
    public static func == (lhs: StartHLSBroadcastingResponse, rhs: StartHLSBroadcastingResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.playlistUrl == rhs.playlistUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(playlistUrl)
    }
}
