//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A class that observes a collection and delays updates based on its size.
/// It uses either debounce or throttle mechanisms to manage update frequency.
final class CollectionDelayedUpdateObserver<Value: Collection>: @unchecked Sendable {
    /// Represents different time intervals for delaying updates.
    enum Interval {
        /// No delay.
        case none
        /// Low delay (0.25 seconds).
        case low
        /// Medium delay (0.5 seconds).
        case medium
        /// High delay (1 second).
        case high
        /// Delay based on the screen's refresh rate.
        case screenRefreshRate

        /// The time interval value associated with each interval case.
        var value: TimeInterval {
            switch self {
            case .none:
                return 0
            case .low:
                return 0.25
            case .medium:
                return 0.5
            case .high:
                return 1
            case .screenRefreshRate:
                return ScreenPropertiesAdapter.currentValue.refreshRate
            }
        }

        /// Initializes an interval based on the collection's count.
        /// - Parameter value: The collection to evaluate.
        init(_ value: Value) {
            let count = value.count
            switch count {
            case _ where count < 16:
                self = .screenRefreshRate
            case _ where count < 50:
                self = .low
            case _ where count < 100:
                self = .medium
            default:
                self = .high
            }
        }
    }

    /// Modes for delaying updates: debounce or throttle.
    enum Mode {
        /// Debounce mode delays updates until a specified time interval has passed without new data.
        case debounce(scheduler: DispatchQueue)
        /// Throttle mode allows updates at most once per specified time interval.
        case throttle(scheduler: DispatchQueue, latest: Bool)
    }

    /// The current interval for delaying updates.
    private(set) var interval: Interval = .screenRefreshRate {
        didSet {
            /// Reconfigure the observer if the interval has changed.
            if interval != oldValue { configure(with: interval) }
        }
    }

    /// The mode used for delaying updates.
    private let mode: Mode
    /// The publisher emitting new collection values.
    private let publisher: AnyPublisher<Value, Never>
    /// A cancellable object to manage the subscription lifecycle.
    private var cancellable: AnyCancellable?

    /// The published collection value.
    @Published private(set) var value: Value

    /// Initializes the observer with a publisher, initial value, and mode.
    /// - Parameters:
    ///   - publisher: A publisher that emits new collection values.
    ///   - value: The initial collection value.
    ///   - mode: The mode for delaying updates (debounce or throttle).
    init(
        publisher: AnyPublisher<Value, Never>,
        initial value: Value,
        mode: Mode
    ) {
        self.mode = mode
        self.publisher = publisher
        self.value = value
        /// Initialize the interval based on the initial value.
        interval = .init(value)
        /// Configure the observer with the initial interval.
        configure(with: interval)
    }

    /// Configures the subscription to handle updates with the specified interval.
    /// - Parameter interval: The time interval to use for delaying updates.
    private func configure(with interval: Interval) {
        /// Logs the update of the interval.
        log.debug("Updating debouncedUpdated interval to \(interval):\(interval.value) seconds.")
        /// Cancels any existing subscription to avoid multiple subscriptions.
        cancellable?.cancel()
        /// Creates a new publisher based on the mode and interval, and subscribes to it.
        cancellable = publisher(for: mode, interval: interval)
            .sink { [weak self] in
                /// Safely unwraps self to prevent retain cycles.
                self?.value = $0
                /// Updates the interval based on the new value's size.
                self?.interval = .init($0)
            }
    }

    /// Creates a publisher that delays emissions based on the mode and interval.
    /// - Parameters:
    ///   - mode: The delay mechanism to use (debounce or throttle).
    ///   - interval: The time interval for delaying updates.
    /// - Returns: A publisher that emits values after applying the delay.
    private func publisher(
        for mode: Mode,
        interval: Interval
    ) -> AnyPublisher<Value, Never> {
        switch interval {
        case .none:
            /// If no delay is needed, return the original publisher.
            return publisher.eraseToAnyPublisher()
        default:
            switch mode {
            case let .debounce(scheduler):
                /// Applies a debounce to the publisher, delaying emissions until no new data arrives
                /// within the interval.
                return publisher
                    .debounce(for: .seconds(interval.value), scheduler: scheduler)
                    .eraseToAnyPublisher()
            case let .throttle(scheduler, latest):
                /// Applies a throttle to the publisher, emitting values at most once per interval.
                return publisher
                    .throttle(for: .seconds(interval.value), scheduler: scheduler, latest: latest)
                    .eraseToAnyPublisher()
            }
        }
    }
}
