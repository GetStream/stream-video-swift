//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/**
 Default real-world implementations of the ``Timer`` protocol.

 These timers are based on ``DispatchQueue`` and ``DispatchSourceTimer``,
 allowing precise control of scheduling on custom queues. This ensures that
 timers are not bound to the main thread and can run in background contexts.
 */
public struct DefaultTimer: Timer {
    /// Schedules a one-shot timer that fires once after the specified interval.
    ///
    /// The timer executes the ``onFire`` callback on the specified dispatch queue,
    /// which can be any background or custom queue. Timers are not tied to the
    /// main thread and can run on any queue you provide.
    ///
    /// - Parameters:
    ///   - timeInterval: Delay in seconds before the timer fires.
    ///   - queue: The dispatch queue on which to execute ``onFire``. This can be
    ///     any queue, including background queues.
    ///   - onFire: Callback to invoke when the timer fires.
    /// - Returns: A ``TimerControl`` used to cancel the timer if needed.
    @discardableResult
    static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl {
        let worker = DispatchWorkItem(block: onFire)
        queue.asyncAfter(deadline: .now() + timeInterval, execute: worker)
        return worker
    }

    /// Schedules a repeating timer on the given queue.
    ///
    /// The timer fires repeatedly at the specified interval. Execution happens
    /// on the provided dispatch queue and is not tied to the main thread. You can
    /// use any custom or background queue for timer events.
    ///
    /// - Parameters:
    ///   - timeInterval: Interval in seconds between timer firings.
    ///   - queue: The dispatch queue used to invoke the ``onFire`` callback.
    ///   - onFire: Callback to invoke on each timer fire.
    /// - Returns: A ``RepeatingTimerControl`` used to manage the timer.
    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        RepeatingTimer(timeInterval: timeInterval, queue: queue, onFire: onFire)
    }

    /// Returns a Combine publisher that emits `Date` values at a fixed interval.
    ///
    /// The timer operates on a background queue and only emits values while
    /// there are active subscribers. If the interval is less than or equal to
    /// zero, a warning is logged and a single `Date` value is emitted instead.
    ///
    /// - Parameters:
    ///   - interval: Time between emitted date values.
    ///   - file: The file from which the method is called. Used for logging.
    ///   - function: The function from which the method is called.
    ///   - line: The line number from which the method is called.
    /// - Returns: A publisher that emits dates while subscribed.
    public static func publish(
        every interval: TimeInterval,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> AnyPublisher<Date, Never> {
        guard interval > 0 else {
            log.warning(
                "Interval cannot be 0 or less",
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            return Just(Date()).eraseToAnyPublisher()
        }
        return TimerPublisher(interval: interval).eraseToAnyPublisher()
    }
}
