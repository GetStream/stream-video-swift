//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class CollectionDelayedUpdateObserver<Value: Collection> {
    private enum Interval {
        case none
        case low
        case medium
        case high
        case screenRefreshRate

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

    enum Mode {
        case debounce(scheduler: DispatchQueue)
        case throttle(scheduler: DispatchQueue, latest: Bool)
    }

    private var interval: Interval = .screenRefreshRate {
        didSet { if interval != oldValue { configure(with: interval) } }
    }

    private let mode: Mode
    private let publisher: AnyPublisher<Value, Never>
    private var cancellable: AnyCancellable?

    @Published private(set) var value: Value

    init(
        publisher: AnyPublisher<Value, Never>,
        initial value: Value,
        mode: Mode
    ) {
        self.mode = mode
        self.publisher = publisher
        self.value = value
        interval = .init(value)
        configure(with: interval)
    }

    private func configure(with interval: Interval) {
        log.debug("Updating debouncedUpdated interval to \(interval):\(interval.value) seconds.")
        cancellable?.cancel()
        cancellable = publisher(for: mode, interval: interval)
            .sink { [weak self] in
                self?.value = $0
                self?.interval = .init($0)
            }
    }

    private func publisher(
        for mode: Mode,
        interval: Interval
    ) -> AnyPublisher<Value, Never> {
        switch interval {
        case .none:
            return publisher.eraseToAnyPublisher()
        default:
            switch mode {
            case let .debounce(scheduler):
                return publisher
                    .debounce(for: .seconds(interval.value), scheduler: scheduler)
                    .eraseToAnyPublisher()
            case let .throttle(scheduler, latest):
                return publisher
                    .throttle(for: .seconds(interval.value), scheduler: scheduler, latest: latest)
                    .eraseToAnyPublisher()
            }
        }
    }
}
