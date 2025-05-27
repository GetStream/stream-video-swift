//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides publishers emitting time events at a set interval.
public protocol TimerProviding {
    /// Returns a publisher that emits the current date every specified interval.
    ///
    /// - Parameter interval: The time interval at which the publisher should emit.
    /// - Returns: A publisher emitting `Date` values on the given interval.
    func timer(for interval: TimeInterval) -> AnyPublisher<Date, Never>
}

/// A concrete implementation of `TimerProviding` that reuses publishers
/// for the same time intervals.
final class TimerStorage: TimerProviding {
    /// A serial queue to synchronize access to the internal storage.
    private let queue = UnfairQueue()

    /// Stores interval-publisher pairs for reuse.
    private var storage: [TimeInterval: AnyPublisher<Date, Never>] = [:]

    /// Creates a new instance of `TimerStorage`.
    init() {}

    /// Returns a shared timer publisher for the given interval. If one already
    /// exists, it is reused. Otherwise, a new one is created and stored.
    ///
    /// - Parameter interval: The time interval at which the timer should tick.
    /// - Returns: A publisher that emits the current date on the main run loop.
    public func timer(for interval: TimeInterval) -> AnyPublisher<Date, Never> {
        queue.sync {
            if let publisher = storage[interval] {
                return publisher
            } else {
                let publisher = Foundation
                    .Timer
                    .publish(every: interval, tolerance: interval, on: .main, in: .common)
                    .autoconnect()
                    .eraseToAnyPublisher()
                storage[interval] = publisher
                return publisher
            }
        }
    }
}

/// An injection key for providing a default `TimerProviding` implementation.
enum TimerProviderKey: InjectionKey {
    /// The default value for the `TimerProviding` dependency.
    nonisolated(unsafe) public static var currentValue: TimerProviding = TimerStorage()
}

extension InjectedValues {
    /// Accessor for the shared `TimerProviding` dependency.
    public var timers: TimerProviding {
        get { Self[TimerProviderKey.self] }
        set { Self[TimerProviderKey.self] = newValue }
    }
}
