//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Emits lifecycle events through the SDK logger.
    final class LogObserver: Observing, @unchecked Sendable {
        private let subsystem: LogSubsystem

        /// Creates a logging observer.
        /// - Parameter subsystem: Logging subsystem for emitted messages.
        init(subsystem: LogSubsystem = .other) {
            self.subsystem = subsystem
        }

        /// Logs a lifecycle event.
        /// - Parameter event: The event to log.
        func record(_ event: Event) {
            let metadataDescription = metadataPayload(from: event.metadata)
            log.debug(
                "[Lifecycle] \(event.typeName) \(event.transition.rawValue) "
                    + "id:\(event.instanceId)\(metadataDescription)",
                subsystems: subsystem
            )
        }

        private func metadataPayload(from metadata: [String: String]) -> String {
            guard metadata.isEmpty == false else {
                return ""
            }

            let pairs = metadata
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ",")

            return " metadata:\(pairs)"
        }
    }
}
