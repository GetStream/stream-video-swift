//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A storage container for caching `TimerPublisher` instances by interval.
///
/// This class provides shared access to a dictionary of `TimerPublisher`
/// instances, ensuring that a single timer is reused for a given interval.
final class TimerStorage {

    /// The shared singleton instance of `TimerStorage`.
    nonisolated(unsafe) static let shared = TimerStorage()

    /// A thread-safe queue used for accessing and modifying the storage.
    private let queue = UnfairQueue()

    /// Internal storage mapping time intervals to their corresponding
    /// `TimerPublisher` instances.
    private var storage: [TimeInterval: TimerPublisher] = [:]

    /// Returns a `TimerPublisher` for the specified time interval.
    ///
    /// If a timer already exists for the interval, it is reused. Otherwise,
    /// a new `TimerPublisher` is created and stored.
    ///
    /// - Parameter interval: The interval in seconds for the timer.
    /// - Returns: A shared `TimerPublisher` for the given interval.
    func timer(for interval: TimeInterval) -> TimerPublisher {
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

extension TimerStorage: InjectionKey {

    /// Provides the current instance of `TimerStorage` used for dependency
    /// injection.
    nonisolated(unsafe) static var currentValue: TimerStorage = .init()
}

extension InjectedValues {

    /// Accessor for `TimerStorage` via dependency injection.
    var timerStorage: TimerStorage {
        get { Self[TimerStorage.self] }
        set { Self[TimerStorage.self] = newValue }
    }
}
