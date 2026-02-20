//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension BatteryStore {

    final class ObserverEffect: StoreEffect<Namespace>, @unchecked Sendable {
        private var lastTransition: Date?
        private var stateCancellable: AnyCancellable?
        private var levelCancellable: AnyCancellable?

        override func set(
            statePublisher: AnyPublisher<BatteryStore.Namespace.StoreState, Never>?
        ) {
            guard let statePublisher else {
                stopLevelObservation()
                return
            }
            let levelPublisher = statePublisher
                .map(\.level)
                .removeDuplicates()
                .eraseToAnyPublisher()

            stateCancellable = statePublisher
                .map(\.state)
                .removeDuplicates()
                .log(.debug) { "Battery charging state changed to \($0)." }
                .sink { [weak self] in
                    switch $0 {
                    case .unplugged:
                        self?.startLevelObservation(levelPublisher)
                    default:
                        self?.stopLevelObservation()
                    }
                }
        }

        // MARK: - Private Helpers

        private func startLevelObservation(_ publisher: AnyPublisher<Int, Never>) {
            levelCancellable?.cancel()
            levelCancellable = nil
            lastTransition = nil

            levelCancellable = publisher
                .log(.debug) { [weak self] in
                    if let lastTransition = self?.lastTransition {
                        let timeDiff = Date().timeIntervalSince(lastTransition)
                        return "Battery level reduced to \($0)%. (\(timeDiff) seconds since last transition)"
                    } else {
                        return "Battery level initial value is \($0)%."
                    }
                }
                .sink { [weak self] _ in self?.lastTransition = Date() }
        }

        private func stopLevelObservation() {
            levelCancellable?.cancel()
            levelCancellable = nil
            lastTransition = nil
        }
    }
}
