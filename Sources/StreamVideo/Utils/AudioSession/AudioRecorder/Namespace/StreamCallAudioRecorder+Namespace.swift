//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallAudioRecorder {
    /// The namespace for the call audio recording store.
    ///
    /// This enum serves as a namespace that defines the store configuration
    /// for managing audio recording during calls. It implements the
    /// ``StoreNamespace`` protocol to provide a complete Redux-like state
    /// management system for audio recording.
    ///
    /// ## Architecture
    ///
    /// The store follows a unidirectional data flow pattern:
    /// 1. Actions are dispatched to trigger state changes
    /// 2. Middleware intercepts actions for side effects
    /// 3. Reducers process actions to produce new state
    /// 4. State changes are published to observers
    ///
    /// ## Components
    ///
    /// - **State**: ``StoreState`` - Holds recording status and audio levels
    /// - **Actions**: ``StoreAction`` - Defines possible state changes
    /// - **Reducers**: Process actions to update state
    /// - **Middleware**: Handle side effects and external interactions
    enum Namespace: StoreNamespace {
        /// The state type for this store namespace.
        typealias State = StoreState

        /// The action type for this store namespace.
        typealias Action = StoreAction

        /// Unique identifier for this store instance.
        ///
        /// Used for logging and debugging purposes.
        static let identifier: String = "call.audio.recording.store"

        /// Returns the reducers that process actions for this store.
        ///
        /// Currently includes:
        /// - ``DefaultReducer``: Handles all state updates
        ///
        /// - Returns: An array of reducers for processing actions.
        static func reducers() -> [Reducer<Namespace>] {
            [
                DefaultReducer()
            ]
        }

        /// Returns the middleware that handle side effects for this store.
        ///
        /// Middleware are applied in order:
        /// 1. ``InterruptionMiddleware``: Monitors audio interruptions
        /// 2. ``CategoryMiddleware``: Monitors audio session category changes
        /// 3. ``AVAudioRecorderMiddleware``: Manages the actual recorder
        /// 4. ``ShouldRecordMiddleware``: Computes `shouldRecord` from call
        ///    `audioOn`, audio‑session `isActive`, and permission
        ///
        /// - Returns: An array of middleware for handling side effects.
        static func middleware() -> [Middleware<Namespace>] {
            [
                InterruptionMiddleware(),
                CategoryMiddleware(),
                AVAudioRecorderMiddleware(),
                ShouldRecordMiddleware()
            ]
        }

        /// Returns the logger for this store.
        ///
        /// Uses a specialized logger that aggregates meter updates to reduce
        /// log noise.
        ///
        /// - Returns: A logger configured for the audio session subsystem.
        static func logger() -> StoreLogger<Namespace> {
            StreamCallAudioRecorderLogger(logSubsystem: .audioSession)
        }
    }
}
