//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import protocol StreamVideo.Timer

struct VirtualTimeTimer: Timer {
    nonisolated(unsafe) static var time: VirtualTime!

    static func invalidate() {
        time.invalidate()
        time = nil
    }

    static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl {
        Self.time.scheduleTimer(
            interval: timeInterval,
            repeating: false,
            callback: { _ in onFire() }
        )
    }

    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        Self.time.scheduleTimer(
            interval: timeInterval,
            repeating: true,
            callback: { _ in onFire() }
        )
    }

    static func publish(
        every interval: TimeInterval,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) -> AnyPublisher<Date, Never> {
        DefaultTimer
            .publish(every: interval)
    }

    static func currentTime() -> Date {
        Date(timeIntervalSinceReferenceDate: time.currentTime)
    }
}
