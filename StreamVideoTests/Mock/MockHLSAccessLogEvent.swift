//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import ObjectiveC

/// An access log event that reports the bitrate it is given.
///
/// AVFoundation offers no initializer for it, so ``make(bitrate:)`` allocates
/// the instance through the Objective-C runtime.
final class MockHLSAccessLogEvent: AVPlayerItemAccessLogEvent, @unchecked Sendable {
    nonisolated(unsafe) var bitrate: Double = 0

    override nonisolated var indicatedBitrate: Double { bitrate }

    /// The other properties the collector reads. The real ones need state
    /// that the runtime allocation does not set up.
    override nonisolated var durationWatched: TimeInterval { 0 }

    override nonisolated var numberOfDroppedVideoFrames: Int { 0 }

    static func make(bitrate: Double) -> MockHLSAccessLogEvent {
        let event = unsafeDowncast(
            class_createInstance(MockHLSAccessLogEvent.self, 0)! as AnyObject,
            to: MockHLSAccessLogEvent.self
        )
        event.bitrate = bitrate
        return event
    }
}
