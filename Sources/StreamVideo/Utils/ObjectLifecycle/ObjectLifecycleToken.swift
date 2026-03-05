//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Emits lifecycle events for one object instance.
    final class Token: @unchecked Sendable {
        /// Stable identifier for the tracked object instance.
        let instanceId: String

        private let observer: Observing
        private let typeName: String
        private let metadata: [String: String]
        private let dateProvider: @Sendable () -> Date

        /// Creates a lifecycle token and emits `.initialized`.
        /// - Parameters:
        ///   - type: Type of the tracked object.
        ///   - metadata: Optional metadata for filtering.
        ///   - observer: Observer receiving lifecycle events.
        ///   - uuidFactory: UUID provider for deterministic tests.
        ///   - dateProvider: Date provider for deterministic tests.
        init(
            type: Any.Type,
            metadata: [String: String] = [:],
            observer: Observing = InjectedValues[\.objectLifecycleObserver],
            uuidFactory: UUIDProviding = InjectedValues[\.uuidFactory],
            dateProvider: @escaping @Sendable () -> Date = Date.init
        ) {
            self.observer = observer
            self.typeName = String(reflecting: type)
            self.metadata = metadata
            self.instanceId = uuidFactory.get().uuidString
            self.dateProvider = dateProvider

            observer.record(event(for: .initialized))
        }

        deinit {
            observer.record(event(for: .deinitialized))
        }

        private func event(for transition: Transition) -> Event {
            .init(
                transition: transition,
                typeName: typeName,
                instanceId: instanceId,
                timestamp: dateProvider(),
                metadata: metadata
            )
        }
    }
}
