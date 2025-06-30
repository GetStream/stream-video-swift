//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A custom Combine publisher that emits `Date` values at a fixed interval.
///
/// The timer is activated only when there is at least one subscriber, and
/// automatically suspended when all subscriptions are cancelled or completed.
final class TimerPublisher: Publisher {
    typealias Output = Date
    typealias Failure = Never

    /// Tracks the current number of active subscriptions. Updates to this
    /// property trigger timer control state changes.
    @Atomic
    private var subscriptions: Int = 0 {
        didSet { didUpdate(subscriptions: subscriptions) }
    }

    /// The interval at which the timer fires.
    private let interval: TimeInterval

    /// The underlying subject that emits the timer events.
    private let subject = PassthroughSubject<Date, Never>()

    /// The timer control used to start and stop the repeating timer. It is
    /// created lazily when the first subscriber connects.
    private lazy var control: RepeatingTimerControl = DefaultTimer.scheduleRepeating(
        timeInterval: interval,
        queue: .global(qos: .default),
        onFire: { [weak self] in self?.subject.send(Date()) }
    )

    private lazy var publisher: AnyPublisher<Date, Never> = subject
        .handleEvents(
            receiveSubscription: { [weak self] _ in self?.didReceiveSubscription() },
            receiveCompletion: { [weak self] _ in self?.didCompleteSubscription() },
            receiveCancel: { [weak self] in self?.didCancelSubscription() }
        )
        .eraseToAnyPublisher()

    /// Creates a new instance of `TimerPublisher` with the given interval.
    ///
    /// - Parameter interval: The time interval between published `Date` values.
    init(interval: TimeInterval) {
        self.interval = interval
        _ = publisher
    }

    /// Registers a subscriber and starts the timer if it's the first one.
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(
            subscription: TimerSubscription(
                subscriber: subscriber,
                publisher: publisher
            )
        )
    }

    // MARK: - Private Helpers

    /// Updates the timer's running state based on the number of subscriptions.
    ///
    /// Suspends the timer when there are no active subscriptions. Resumes it
    /// when a single subscription is added and the timer is not running.
    private func didUpdate(subscriptions: Int) {
        switch subscriptions {
        case _ where subscriptions <= 0:
            control.suspend()
            LogConfig.logger.debug("TimerPublisher interval:\(interval) is now suspended.")
        case 1 where !control.isRunning:
            control.resume()
            LogConfig.logger.debug("TimerPublisher interval:\(interval) is now resuming.")
        default:
            break
        }
    }

    /// Called when a new subscription is received.
    private func didReceiveSubscription() {
        subscriptions += 1
    }

    /// Called when a subscription completes.
    private func didCompleteSubscription() {
        subscriptions -= 1
    }

    /// Called when a subscription is cancelled.
    private func didCancelSubscription() {
        subscriptions -= 1
    }
}

extension TimerPublisher {

    /// A subscription wrapper that forwards values from the publisher to the
    /// subscriber and manages its cancellation lifecycle.
    private final class TimerSubscription<S: Subscriber>: Subscription where S.Input == Date, S.Failure == Never {
        /// The downstream subscriber.
        private var subscriber: S?

        /// The cancellable reference to the source publisher.
        private var cancellable: AnyCancellable?

        /// Creates a new `TimerSubscription` with a wrapped publisher.
        ///
        /// - Parameters:
        ///   - subscriber: The subscriber to forward values to.
        ///   - publisher: The source publisher emitting `Date` values.
        init(
            subscriber: S,
            publisher: AnyPublisher<Date, Never>
        ) {
            self.subscriber = subscriber
            cancellable = publisher
                .sink { [weak self] in _ = self?.subscriber?.receive($0) }
        }

        /// Requests a certain number of values. Ignored in this implementation
        /// since values are emitted on a schedule.
        func request(_ demand: Subscribers.Demand) {
            // demand is ignored because we send Date events on a schedule
        }

        /// Cancels the subscription and cleans up any resources.
        func cancel() {
            subscriber = nil
            cancellable?.cancel()
            cancellable = nil
        }
    }
}
