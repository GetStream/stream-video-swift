//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension PlaybackResponse {
    static func dummy(
        playlistUrl: String = "https://example.com/live.m3u8",
        reason: PlaybackResponseReason = .percentage,
        statsToken: String? = nil,
        type: PlaybackResponseType = .hls
    ) -> PlaybackResponse {
        .init(
            playlistUrl: playlistUrl,
            reason: reason,
            statsToken: statsToken,
            type: type
        )
    }
}
