//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

public protocol Timer {
    /// Schedules a new timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds after which the timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `TimerControl` where you can cancel the timer.
    @discardableResult
    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl

    static func publish(every: TimeInterval) -> AnyPublisher<Date, Never>

    /// Schedules a new repeating timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds between timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `RepeatingTimerControl` where you can suspend and resume the timer.
    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl

    /// Returns the current date and time.
    static func currentTime() -> Date
}

extension Timer {
    public static func currentTime() -> Date {
        Date()
    }
}

/// Allows resuming and suspending of a timer.
public protocol RepeatingTimerControl {
    /// Resumes the timer.
    func resume()

    /// Pauses the timer.
    func suspend()
}

/// Allows cancelling a timer.
public protocol TimerControl {
    /// Cancels the timer.
    func cancel()
}

extension DispatchWorkItem: TimerControl {}

/// Default real-world implementations of timers.
public struct DefaultTimer: Timer {
    @discardableResult
    public static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl {
        let worker = DispatchWorkItem(block: onFire)
        queue.asyncAfter(deadline: .now() + timeInterval, execute: worker)
        return worker
    }

    public static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        RepeatingTimer(timeInterval: timeInterval, queue: queue, onFire: onFire)
    }

    public static func publish(every: TimeInterval) -> AnyPublisher<Date, Never> {
        TimerPublisher(interval: every).eraseToAnyPublisher()
    }
}

private class RepeatingTimer: RepeatingTimerControl, @unchecked Sendable {
    private enum State {
        case suspended
        case resumed
    }

    private let queue = DispatchQueue(label: "io.getstream.repeating-timer")
    private var state: State = .suspended
    private let timer: DispatchSourceTimer

    init(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(Int(timeInterval)), repeating: timeInterval, leeway: .seconds(1))
        timer.setEventHandler(handler: onFire)
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        if state == .suspended {
            timer.resume()
        }
    }

    func resume() {
        queue.async {
            if self.state == .resumed {
                return
            }

            self.state = .resumed
            self.timer.resume()
        }
    }

    func suspend() {
        queue.async {
            if self.state == .suspended {
                return
            }

            self.state = .suspended
            self.timer.suspend()
        }
    }
}

private final class TimerPublisher: Publisher {
    typealias Output = Date
    typealias Failure = Never

    private let interval: TimeInterval

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = TimerSubscription(subscriber: subscriber, interval: interval)
        subscriber.receive(subscription: subscription)
    }

    private final class TimerSubscription<S: Subscriber>: Subscription where S.Input == Date, S.Failure == Never {
        private var subscriber: S?
        private var control: RepeatingTimerControl?

        init(subscriber: S, interval: TimeInterval) {
            self.subscriber = subscriber
            control = DefaultTimer.scheduleRepeating(
                timeInterval: interval,
                queue: .global(qos: .default)
            ) { [weak self] in
                _ = self?.subscriber?.receive(Date())
            }
            control?.resume()
        }

        func request(_ demand: Subscribers.Demand) {
            // demand is ignored because we send Date events on a schedule
        }

        func cancel() {
            subscriber = nil
            control?.suspend()
            control = nil
        }
    }
}
