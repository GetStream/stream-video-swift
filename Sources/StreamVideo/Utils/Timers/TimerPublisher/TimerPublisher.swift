//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A custom Combine publisher that emits `Date` values at a fixed interval.
///
/// The timer emits values from a background queue and only runs when there is
/// at least one active subscriber. It automatically suspends when no
/// subscribers remain.
final class TimerPublisher: Publisher {
    typealias Output = Date
    typealias Failure = Never

    /// The interval at which the timer fires, in seconds.
    private let interval: TimeInterval

    /// Creates a new instance of `TimerPublisher` with the specified interval.
    ///
    /// - Parameter interval: The interval in seconds between published dates.
    init(interval: TimeInterval) {
        self.interval = interval
    }

    /// Registers a subscriber and starts emitting dates on a background queue.
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(
            subscription: TimerSubscription(
                subscriber: subscriber,
                interval: interval
            )
        )
    }
}

extension TimerPublisher {

    /// A subscription wrapper that handles timer events and lifecycle.
    ///
    /// Emits `Date` values to the subscriber while the timer is active. It
    /// ensures the timer is only started once and safely suspended on cancel.
    private final class TimerSubscription<S: Subscriber>: Subscription where S.Input == Date, S.Failure == Never {
        /// The downstream subscriber receiving the date values.
        private var subscriber: S?

        /// The repeating timer control that emits values at a fixed interval.
        private var control: RepeatingTimerControl?

        /// The timestamp marking when the subscription was initialized. We keep a reference
        /// to check when the first firing of our Timer block will occur. If it's before the interval we are
        /// skipping upstream call.
        private let registeringTime: Date = .init()

        /// Initializes the subscription and starts the timer.
        ///
        /// - Parameters:
        ///   - subscriber: The subscriber to receive emitted date values.
        ///   - interval: The interval in seconds between emissions.
        init(
            subscriber: S,
            interval: TimeInterval
        ) {
            self.subscriber = subscriber
            control = DefaultTimer.scheduleRepeating(
                timeInterval: interval,
                queue: .global(qos: .default),
                onFire: { [weak self] in
                    let value = Date()
                    guard
                        let self,
                        value.timeIntervalSince(registeringTime) >= interval
                    else {
                        return
                    }
                    _ = subscriber.receive(value)
                }
            )
            control?.resume()
        }

        /// Requests values from the publisher.
        ///
        /// This is ignored because values are pushed on a fixed schedule.
        func request(_ demand: Subscribers.Demand) {
            // demand is ignored because we send Date events on a schedule
        }

        /// Cancels the timer and cleans up the subscriber reference.
        func cancel() {
            subscriber = nil
            control?.suspend()
            control = nil
        }
    }
}
