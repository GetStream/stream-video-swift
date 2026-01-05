//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol describing a timing utility for scheduling one-shot and repeating
/// timers, as well as retrieving the current time or publishing timer events.
///
/// All scheduled timers are executed on the provided dispatch queue, which
/// allows running timers off the main thread in background contexts.
protocol Timer {

    /// Schedules a new one-shot timer on the specified queue.
    ///
    /// The timer fires once after the given time interval. The `onFire` callback
    /// is invoked on the provided dispatch queue, which is not restricted to the
    /// main thread.
    ///
    /// - Parameters:
    ///   - timeInterval: Seconds until the timer fires.
    ///   - queue: The queue where the `onFire` callback is executed. It can be a
    ///     background queue.
    ///   - onFire: Callback triggered when the timer fires.
    /// - Returns: A `TimerControl` that can cancel the scheduled timer.
    @discardableResult
    static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl

    /// Schedules a new repeating timer on the specified queue.
    ///
    /// The timer repeatedly fires after the specified time interval. The `onFire`
    /// callback is invoked on the provided dispatch queue, which can be a
    /// background queue and is not tied to the main thread.
    ///
    /// - Parameters:
    ///   - timeInterval: Seconds between repeated timer firings.
    ///   - queue: The queue on which the `onFire` callback is executed.
    ///   - onFire: Callback triggered each time the timer fires.
    /// - Returns: A `RepeatingTimerControl` that allows suspension and resumption.
    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl

    /// Returns the current system date and time.
    static func currentTime() -> Date

    /// Returns a publisher that emits timer events at the specified interval.
    ///
    /// This publisher is designed to emit values from a background context and
    /// is not restricted to the main thread.
    ///
    /// - Parameters:
    ///   - interval: Time between emitted `Date` values.
    ///   - repeating: A Boolean indicating if the timer should repeat.
    /// - Returns: A publisher that emits the current `Date` on each fire.
    static func publish(
        every interval: TimeInterval,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) -> AnyPublisher<Date, Never>
}

extension Timer {

    /// Returns the current system date and time.
    static func currentTime() -> Date {
        Date()
    }
}
