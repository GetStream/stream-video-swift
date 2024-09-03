//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class CollectionDebouncedUpdateObserver<Value: Collection> {
    private enum DebounceInterval: TimeInterval {
        case none = 0
        case low = 0.25
        case medium = 0.5
        case high = 1

        init(_ value: Value) {
            let count = value.count
            switch count {
            case _ where count < 16:
                self = .none
            case _ where count < 50:
                self = .low
            case _ where count < 100:
                self = .medium
            default:
                self = .high
            }
        }
    }

    private var interval: DebounceInterval = .none {
        didSet { if interval != oldValue { configure(with: interval) } }
    }

    private let publisher: AnyPublisher<Value, Never>
    private let scheduler: DispatchQueue
    private var cancellable: AnyCancellable?

    @Published private(set) var value: Value

    init(
        publisher: AnyPublisher<Value, Never>,
        initial value: Value,
        on scheduler: DispatchQueue = DispatchQueue.main
    ) {
        self.publisher = publisher
        self.value = value
        self.scheduler = scheduler
        interval = .init(value)
        configure(with: interval)
    }

    private func configure(with interval: DebounceInterval) {
        log.debug("Updating debouncedUpdated interval to \(interval):\(interval.rawValue) seconds.")
        cancellable?.cancel()
        if interval == .none {
            cancellable = publisher
                .sink { [weak self] in
                    self?.value = $0
                    self?.interval = .init($0)
                }
        } else {
            cancellable = publisher
                .debounce(for: .seconds(interval.rawValue), scheduler: scheduler)
                .sink { [weak self] in
                    self?.value = $0
                    self?.interval = .init($0)
                }
        }
    }
}
