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
        private let queue = UnfairQueue()
        private var metadata: [String: String]
        private let dateProvider: @Sendable () -> Date

        fileprivate init(
            instanceId: String,
            observer: Observing,
            typeName: String,
            metadata: [String : String],
            dateProvider: @escaping @Sendable () -> Date
        ) {
            self.instanceId = instanceId
            self.observer = observer
            self.typeName = typeName
            self.metadata = metadata
            self.dateProvider = dateProvider

            observer.record(
                event(
                    for: .initialized,
                    metadata: metadata
                )
            )
        }

        deinit {
            let deinitializedEvent = queue.sync {
                event(
                    for: .deinitialized,
                    metadata: metadata
                )
            }

            observer.record(deinitializedEvent)
        }

        /// Replaces the token metadata and emits `.metadataUpdated`.
        /// - Parameter metadata: The new metadata payload.
        func updateMetadata(_ metadata: [String: String]) {
            let metadataUpdatedEvent = queue.sync { () -> Event? in
                guard self.metadata != metadata else {
                    return nil
                }

                self.metadata = metadata

                return event(
                    for: .metadataUpdated,
                    metadata: metadata
                )
            }

            if let metadataUpdatedEvent {
                observer.record(metadataUpdatedEvent)
            }
        }

        private func event(
            for transition: Transition,
            metadata: [String: String]
        ) -> Event {
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

extension ObjectLifecycle.Token {

    /// Creates a lifecycle token and emits `.initialized`.
    /// - Parameters:
    ///   - type: Type of the tracked object.
    ///   - metadata: Optional metadata for filtering.
    ///   - observer: Observer receiving lifecycle events.
    ///   - uuidFactory: UUID provider for deterministic tests.
    ///   - dateProvider: Date provider for deterministic tests.
    convenience init(
        type: Any.Type,
        metadata: [String: String] = [:],
        observer: ObjectLifecycle.Observing = InjectedValues[\.objectLifecycleObserver],
        uuidFactory: UUIDProviding = InjectedValues[\.uuidFactory],
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.init(
            instanceId: uuidFactory.get().uuidString,
            observer: observer,
            typeName: String(reflecting: type),
            metadata: metadata,
            dateProvider: dateProvider
        )
    }

    convenience init(
        _ instance: Call,
        observer: ObjectLifecycle.Observing = InjectedValues[\.objectLifecycleObserver],
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.init(
            instanceId: instance.cId,
            observer: observer,
            typeName: String(reflecting: type(of: instance)),
            metadata: [
                "user.id": instance.streamVideo.user.id,
                "user.name": instance.streamVideo.user.name,
                "stream.connection.id": instance.streamVideo.connectionId ?? "-"
            ],
            dateProvider: dateProvider
        )
    }

    convenience init(
        _ instance: StreamVideo,
        observer: ObjectLifecycle.Observing = InjectedValues[\.objectLifecycleObserver],
        uuidFactory: UUIDProviding = InjectedValues[\.uuidFactory],
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.init(
            instanceId: uuidFactory.get().uuidString,
            observer: observer,
            typeName: String(reflecting: type(of: instance)),
            metadata: [
                "user.id": instance.user.id,
                "user.name": instance.user.name,
                "stream.connection.id": instance.connectionId ?? "-"
            ],
            dateProvider: dateProvider
        )
    }
}

extension ObjectLifecycle.Token {

    func updateMetadata(for instance: Call) async {
        await self.updateMetadata([
            "session.id": instance.state.sessionId,
            "user.id": instance.streamVideo.user.id,
            "user.name": instance.streamVideo.user.name,
            "stream.connection.id": instance.streamVideo.connectionId ?? "-",
        ])
    }

    func updateMetadata(for instance: StreamVideo) {
        self.updateMetadata([
            "user.id": instance.user.id,
            "user.name": instance.user.name,
            "stream.connection.id": instance.connectionId ?? "-"
        ])
    }
}
