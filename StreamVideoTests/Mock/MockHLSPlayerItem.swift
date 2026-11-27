//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Reports the seekable range, live offset, and load status it is given.
final class MockHLSPlayerItem: AVPlayerItem, @unchecked Sendable {
    nonisolated(unsafe) var ranges: [CMTimeRange] = []
    nonisolated(unsafe) var liveOffset: CMTime = .invalid
    private nonisolated(unsafe) var stubbedStatus: AVPlayerItem.Status = .unknown

    override nonisolated var seekableTimeRanges: [NSValue] {
        ranges.map { NSValue(timeRange: $0) }
    }

    override nonisolated var recommendedTimeOffsetFromLive: CMTime { liveOffset }

    override nonisolated var status: AVPlayerItem.Status { stubbedStatus }

    /// Changes the status the way the system does, so observers fire.
    nonisolated func simulate(status: AVPlayerItem.Status) {
        willChangeValue(forKey: "status")
        stubbedStatus = status
        didChangeValue(forKey: "status")
    }
}
