//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides publishers emitting time events at a
/// configurable interval.
public protocol TimerProviding {
    /// Returns a publisher that emits the current date at the given interval.
    ///
    /// - Parameter interval: The interval at which the publisher emits values.
    /// - Returns: A publisher emitting `Date` values on the specified interval.
    func timer(
        for interval: TimeInterval
    ) -> AnyPublisher<Date, Never>

    /// Returns a publisher that emits the current date at the given interval
    /// with a specified tolerance.
    ///
    /// - Parameters:
    ///   - interval: The interval at which the publisher emits values.
    ///   - tolerance: The tolerance to apply to the timer.
    /// - Returns: A publisher emitting `Date` values on the specified interval.
    func timer(
        for interval: TimeInterval,
        tolerance: TimeInterval
    ) -> AnyPublisher<Date, Never>
}

/// A concrete implementation of `TimerProviding` that caches and reuses
/// timer publishers for identical intervals.
final class TimerStorage: TimerProviding {
    typealias Factory = (TimeInterval, TimeInterval) -> AnyPublisher<Date, Never>

    /// A serial queue used to synchronize access to the timer storage.
    private let queue = UnfairQueue()
    /// Factory closure used to construct new timer publishers.
    private let factory: Factory
    /// Cached map of timer publishers keyed by interval.
    private var storage: [TimeInterval: AnyPublisher<Date, Never>] = [:]

    convenience init() {
        self.init { interval, tolerance in
            Foundation
                .Timer
                .publish(every: interval, tolerance: tolerance, on: .main, in: .common)
                .autoconnect()
                .eraseToAnyPublisher()
        }
    }

    /// Creates a `TimerStorage` instance using a custom factory.
    ///
    /// - Parameter factory: A closure that builds a timer publisher given
    ///   an interval and tolerance.
    init(_ factory: @escaping Factory) {
        self.factory = factory
    }

    /// Returns a shared timer publisher for the specified interval using
    /// a default tolerance equal to 0.
    ///
    /// - Parameter interval: The interval at which the timer should emit.
    /// - Returns: A shared timer publisher.
    public func timer(
        for interval: TimeInterval
    ) -> AnyPublisher<Date, Never> {
        timer(
            for: interval,
            tolerance: 0
        )
    }

    /// Returns a shared timer publisher for the given interval and tolerance.
    ///
    /// - Parameters:
    ///   - interval: The interval at which the timer emits.
    ///   - tolerance: The allowed variation in the timer firing.
    /// - Returns: A shared timer publisher.
    public func timer(
        for interval: TimeInterval,
        tolerance: TimeInterval
    ) -> AnyPublisher<Date, Never> {
        queue.sync {
            if let publisher = storage[interval] {
                return publisher
            } else {
                let publisher = factory(interval, tolerance)
                storage[interval] = publisher
                return publisher
            }
        }
    }
}

/// An injection key used to provide a `TimerProviding` instance.
enum TimerProviderKey: InjectionKey {
    /// The default `TimerProviding` value injected into the environment.
    nonisolated(unsafe) public static var currentValue: TimerProviding = TimerStorage()
}

extension InjectedValues {
    /// Accessor for the environment's current `TimerProviding` instance.
    public var timers: TimerProviding {
        get { Self[TimerProviderKey.self] }
        set { Self[TimerProviderKey.self] = newValue }
    }
}
