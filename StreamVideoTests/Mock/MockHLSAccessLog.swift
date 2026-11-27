//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import ObjectiveC

/// An access log that returns the events it is given.
///
/// AVFoundation offers no initializer for it, so ``make(events:)`` allocates
/// the instance through the Objective-C runtime.
final class MockHLSAccessLog: AVPlayerItemAccessLog, @unchecked Sendable {
    nonisolated(unsafe) var stubbedEvents: [AVPlayerItemAccessLogEvent] = []

    override nonisolated var events: [AVPlayerItemAccessLogEvent] { stubbedEvents }

    static func make(events: [AVPlayerItemAccessLogEvent]) -> MockHLSAccessLog {
        let log = unsafeDowncast(
            class_createInstance(MockHLSAccessLog.self, 0)! as AnyObject,
            to: MockHLSAccessLog.self
        )
        log.stubbedEvents = events
        return log
    }
}
