//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StartHLSBroadcastingResponse is the payload for starting an HLS broadcasting.
public final class StartHLSBroadcastingResponse: @unchecked Sendable, Decodable {
    public var duration: String
    /// the URL of the HLS playlist
    public var playlistUrl: String

    public init(duration: String, playlistUrl: String) {
        self.duration = duration
        self.playlistUrl = playlistUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.playlistUrl = try container.decode(String.self, forKey: .playlistUrl)
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
