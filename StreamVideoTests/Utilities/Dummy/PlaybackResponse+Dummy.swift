//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension PlaybackResponse {
    static func dummy(
        playlistUrl: String = "https://example.com/live.m3u8",
        reason: PlaybackResponseReason = .percentage,
        type: PlaybackResponseType = .hls
    ) -> PlaybackResponse {
        .init(
            playlistUrl: playlistUrl,
            reason: reason,
            type: type
        )
    }
}
