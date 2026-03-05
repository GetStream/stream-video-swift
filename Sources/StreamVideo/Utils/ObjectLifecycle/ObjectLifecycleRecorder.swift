//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Records lifecycle events and provides query APIs for diagnostics.
    final class Recorder: Observing, @unchecked Sendable {
        /// Transition counters per tracked type.
        struct Counts: Sendable, Equatable {
            /// Number of `.initialized` events.
            var initialized: Int
            /// Number of `.deinitialized` events.
            var deinitialized: Int

            /// The number of currently alive instances.
            var live: Int {
                initialized - deinitialized
            }

            static let zero = Counts(initialized: 0, deinitialized: 0)
        }

        private struct InstanceKey: Hashable {
            let typeName: String
            let instanceId: String
        }

        private struct State {
            var countsByType: [String: Counts] = [:]
            var liveInstances: Set<InstanceKey> = []
            var events: [Event] = []
        }

        private let queue = UnfairQueue()
        private var state = State()
        private let maxStoredEvents: Int

        /// Creates a recorder.
        /// - Parameter maxStoredEvents: Maximum events kept in memory.
        init(maxStoredEvents: Int = 1_000) {
            self.maxStoredEvents = max(maxStoredEvents, 0)
        }

        /// Records a lifecycle event.
        /// - Parameter event: The event to record.
        func record(_ event: Event) {
            queue.sync {
                var counts = state.countsByType[event.typeName] ?? .zero

                switch event.transition {
                case .initialized:
                    counts.initialized += 1
                    state.liveInstances.insert(
                        .init(
                            typeName: event.typeName,
                            instanceId: event.instanceId
                        )
                    )
                case .deinitialized:
                    counts.deinitialized += 1
                    state.liveInstances.remove(
                        .init(
                            typeName: event.typeName,
                            instanceId: event.instanceId
                        )
                    )
                }

                state.countsByType[event.typeName] = counts
                append(event)
            }
        }

        /// Returns transition counters for a type.
        /// - Parameter type: The type to inspect.
        /// - Returns: The recorded counters for the type.
        func counts(for type: Any.Type) -> Counts {
            counts(forTypeName: Self.typeName(for: type))
        }

        /// Returns transition counters for a type name.
        /// - Parameter typeName: The reflected type name.
        /// - Returns: The recorded counters for the type.
        func counts(forTypeName typeName: String) -> Counts {
            queue.sync {
                state.countsByType[typeName] ?? .zero
            }
        }

        /// Returns currently alive instance count for a type.
        /// - Parameter type: The type to inspect.
        /// - Returns: Number of live instances.
        func liveCount(for type: Any.Type) -> Int {
            counts(for: type).live
        }

        /// Returns initialization count for a type.
        /// - Parameter type: The type to inspect.
        /// - Returns: Number of initialization events.
        func initializedCount(for type: Any.Type) -> Int {
            counts(for: type).initialized
        }

        /// Returns deinitialization count for a type.
        /// - Parameter type: The type to inspect.
        /// - Returns: Number of deinitialization events.
        func deinitializedCount(for type: Any.Type) -> Int {
            counts(for: type).deinitialized
        }

        /// Checks if a specific instance id is currently alive.
        /// - Parameters:
        ///   - type: The type to inspect.
        ///   - instanceId: The instance identifier.
        /// - Returns: `true` when the instance is still alive.
        func isAlive(for type: Any.Type, instanceId: String) -> Bool {
            queue.sync {
                state.liveInstances.contains(
                    .init(
                        typeName: Self.typeName(for: type),
                        instanceId: instanceId
                    )
                )
            }
        }

        /// Returns events matching the provided filters.
        /// - Parameters:
        ///   - type: Optional type filter.
        ///   - transition: Optional transition filter.
        ///   - metadata: Metadata keys and values that must all match.
        /// - Returns: Matching lifecycle events.
        func events(
            for type: Any.Type? = nil,
            transition: Transition? = nil,
            metadata: [String: String] = [:]
        ) -> [Event] {
            let typeName = type.map(Self.typeName(for:))

            return queue.sync {
                state.events.filter { event in
                    guard typeName == nil || event.typeName == typeName else {
                        return false
                    }

                    guard
                        transition == nil || event.transition == transition
                    else {
                        return false
                    }

                    return metadata.allSatisfy { key, value in
                        event.metadata[key] == value
                    }
                }
            }
        }

        /// Checks whether a matching event exists.
        /// - Parameters:
        ///   - type: Type filter.
        ///   - transition: Transition filter.
        ///   - metadata: Required metadata.
        /// - Returns: `true` when a matching event exists.
        func containsEvent(
            for type: Any.Type,
            transition: Transition,
            metadata: [String: String] = [:]
        ) -> Bool {
            events(for: type, transition: transition, metadata: metadata)
                .isEmpty == false
        }

        /// Checks whether a matching event exists for a specific instance.
        /// - Parameters:
        ///   - type: Type filter.
        ///   - transition: Transition filter.
        ///   - instanceId: Instance identifier filter.
        /// - Returns: `true` when a matching event exists.
        func containsEvent(
            for type: Any.Type,
            transition: Transition,
            instanceId: String
        ) -> Bool {
            let typeName = Self.typeName(for: type)

            return queue.sync {
                state.events.contains {
                    $0.typeName == typeName
                        && $0.transition == transition
                        && $0.instanceId == instanceId
                }
            }
        }

        /// Clears all recorded data.
        func reset() {
            queue.sync {
                state = .init()
            }
        }

        private func append(_ event: Event) {
            guard maxStoredEvents > 0 else {
                return
            }

            state.events.append(event)
            let overflow = state.events.count - maxStoredEvents
            if overflow > 0 {
                state.events.removeFirst(overflow)
            }
        }

        private static func typeName(for type: Any.Type) -> String {
            String(reflecting: type)
        }
    }
}
