//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Middleware that handles application state transitions for audio
    /// recording.
    ///
    /// This middleware ensures recording continuity across app state
    /// changes (foreground/background transitions). When the app state
    /// changes while recording is active, it briefly stops and restarts
    /// recording to maintain proper audio session configuration.
    ///
    /// ## Purpose
    ///
    /// iOS may reconfigure the audio session when the app transitions
    /// between states. This middleware ensures the recorder adapts to
    /// these changes without losing functionality.
    final class ApplicationStateMiddleware: Middleware<StreamCallAudioRecorder.Namespace>, @unchecked Sendable {
        /// Adapter for monitoring application state changes.
        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        /// Container for managing subscription lifecycles.
        private let disposableBag = DisposableBag()
        
        /// Subscription to monitor application state changes.
        private var activeCallCancellable: AnyCancellable?
        
        /// Unused subscription placeholder for future enhancements.
        private var callSettingsCancellable: AnyCancellable?

        /// Initializes the middleware and sets up app state monitoring.
        override init() {
            super.init()

            // Monitor application state changes
            activeCallCancellable = applicationStateAdapter
                .statePublisher
                .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didUpdate($0) }
        }

        // MARK: - Private Helpers

        /// Handles application state transitions while recording.
        ///
        /// When the app state changes during active recording, this method
        /// performs a quick restart of the recording to ensure proper audio
        /// session configuration.
        ///
        /// - Parameter applicationState: The new application state.
        ///
        /// - Note: The 250ms delay allows the audio session to properly
        ///   reconfigure before restarting recording.
        private func didUpdate(_ applicationState: ApplicationState) async {
            guard state?.isRecording == true else {
                return
            }

            // Briefly stop and restart recording
            dispatcher?.dispatch(.setIsRecording(false))
            dispatcher?.dispatch(.setIsRecording(true), delay: .init(before: 0.25)) // 250ms delay
        }
    }
}
