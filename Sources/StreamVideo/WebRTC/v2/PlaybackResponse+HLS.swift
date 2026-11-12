//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PlaybackResponse {

    /// The URL of the HLS playlist the backend granted.
    ///
    /// - Throws: A ``ClientError`` when the grant is not an HLS grant or when
    ///   the playlist URL is not an absolute `https` URL.
    func hlsPlaylistURL() throws -> URL {
        guard type == .hls else {
            throw ClientError("Unsupported playback type \(type.rawValue).")
        }
        guard
            let url = URL(string: playlistUrl),
            url.scheme?.lowercased() == "https",
            url.host?.isEmpty == false
        else {
            throw ClientError("Invalid HLS playlist URL.")
        }
        return url
    }
}
