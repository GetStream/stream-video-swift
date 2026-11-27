//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Reports the seekable range, live offset, bitrate, load status, and failure
/// it is given.
final class MockHLSPlayerItem: AVPlayerItem, @unchecked Sendable {
    nonisolated(unsafe) var ranges: [CMTimeRange] = []
    nonisolated(unsafe) var liveOffset: CMTime = .invalid
    nonisolated(unsafe) var size: CGSize = .zero
    /// The indicated bitrate in bits per second. Zero has no access log.
    nonisolated(unsafe) var bitrate: Double = 0
    private nonisolated(unsafe) var stubbedStatus: AVPlayerItem.Status = .unknown
    private nonisolated(unsafe) var stubbedError: Error?

    override nonisolated var seekableTimeRanges: [NSValue] {
        ranges.map { NSValue(timeRange: $0) }
    }

    override nonisolated var recommendedTimeOffsetFromLive: CMTime { liveOffset }

    override nonisolated var presentationSize: CGSize { size }

    override nonisolated func accessLog() -> AVPlayerItemAccessLog? {
        guard bitrate > 0 else { return nil }
        return MockHLSAccessLog.make(events: [MockHLSAccessLogEvent.make(bitrate: bitrate)])
    }

    override nonisolated var status: AVPlayerItem.Status { stubbedStatus }

    override nonisolated var error: Error? { stubbedError }

    /// Changes the status the way the system does, so observers fire.
    nonisolated func simulate(status: AVPlayerItem.Status) {
        willChangeValue(forKey: "status")
        stubbedStatus = status
        didChangeValue(forKey: "status")
    }

    /// Fails the item the way the system does, so observers fire.
    nonisolated func fail(with error: Error) {
        willChangeValue(forKey: "error")
        willChangeValue(forKey: "status")
        stubbedError = error
        stubbedStatus = .failed
        didChangeValue(forKey: "status")
        didChangeValue(forKey: "error")
    }
}
