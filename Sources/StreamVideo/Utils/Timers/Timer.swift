//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

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

    var isActive: Bool { get }
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

    public static func publish(every interval: TimeInterval) -> AnyPublisher<Date, Never> {
        guard interval > 0 else {
            log.assert(interval > 0, "Interval should be greater than 0")
            return Just(Date()).eraseToAnyPublisher()
        }
        return TimerStorage.shared.acquire(for: interval).eraseToAnyPublisher()
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

    var isActive: Bool { state == .resumed }

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

final class TimerStorage {
    private let queue = UnfairQueue()
    private var storage: [TimeInterval: TimerPublisher] = [:]
    nonisolated(unsafe) static let shared = TimerStorage()

    func acquire(for interval: TimeInterval) -> TimerPublisher {
        queue.sync {
            if let control = storage[interval] {
                return control
            } else {
                let control = TimerPublisher(interval: interval)
                storage[interval] = control
                return control
            }
        }
    }
}

final class TimerPublisher: Publisher {
    typealias Output = Date
    typealias Failure = Never

    @Atomic private var subscriptions: Int = 0 {
        didSet {
            if subscriptions <= 0 {
                control.suspend()
                LogConfig.logger.debug("TimerPublisher interval:\(interval) is now suspended.")
            } else if subscriptions >= 1, !control.isActive {
                control.resume()
                LogConfig.logger.debug("TimerPublisher interval:\(interval) is now resuming.")
            }
        }
    }

    private let interval: TimeInterval
    private let subject = PassthroughSubject<Date, Never>()
    private lazy var control: RepeatingTimerControl = DefaultTimer.scheduleRepeating(
        timeInterval: interval,
        queue: .global(qos: .default),
        onFire: { [weak self] in self?.subject.send(Date()) }
    )

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = TimerSubscription(
            subscriber: subscriber,
            publisher: subject
                .handleEvents(
                    receiveSubscription: { [weak self] _ in
                        self?.subscriptions += 1
                    },
                    receiveCompletion: { [weak self] _ in
                        self?.subscriptions -= 1
                    },
                    receiveCancel: { [weak self] in
                        self?.subscriptions -= 1
                    }
                )
                .eraseToAnyPublisher()
        )
        subscriber.receive(subscription: subscription)
    }

    private final class TimerSubscription<S: Subscriber>: Subscription where S.Input == Date, S.Failure == Never {
        private var subscriber: S?
        private var cancellable: AnyCancellable?

        init(subscriber: S, publisher: AnyPublisher<Date, Never>) {
            self.subscriber = subscriber
            cancellable = publisher
                .sink { [weak self] in _ = self?.subscriber?.receive($0) }
        }

        func request(_ demand: Subscribers.Demand) {
            // demand is ignored because we send Date events on a schedule
        }

        func cancel() {
            subscriber = nil
            cancellable?.cancel()
            cancellable = nil
        }
    }
}
