//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Reports the seekable range and live offset it is given.
final class MockHLSPlayerItem: AVPlayerItem, @unchecked Sendable {
    nonisolated(unsafe) var ranges: [CMTimeRange] = []
    nonisolated(unsafe) var liveOffset: CMTime = .invalid

    override nonisolated var seekableTimeRanges: [NSValue] {
        ranges.map { NSValue(timeRange: $0) }
    }

    override nonisolated var recommendedTimeOffsetFromLive: CMTime { liveOffset }
}
