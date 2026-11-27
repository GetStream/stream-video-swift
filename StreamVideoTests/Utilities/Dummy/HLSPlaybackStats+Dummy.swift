//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension HLSPlaybackStats {
    static func dummy(
        bitrateKbps: Int = 0,
        bufferLengthMs: Int = 0,
        droppedFrames: Int = 0,
        height: Int = 0,
        liveLatencyMs: Int = 0,
        maxStallDurationMs: Int = 0,
        stallCount: Int = 0,
        stallDurationMs: Int = 0,
        watchDurationMs: Int = 0,
        width: Int = 0
    ) -> HLSPlaybackStats {
        .init(
            bitrateKbps: bitrateKbps,
            bufferLengthMs: bufferLengthMs,
            droppedFrames: droppedFrames,
            height: height,
            liveLatencyMs: liveLatencyMs,
            maxStallDurationMs: maxStallDurationMs,
            stallCount: stallCount,
            stallDurationMs: stallDurationMs,
            watchDurationMs: watchDurationMs,
            width: width
        )
    }
}
