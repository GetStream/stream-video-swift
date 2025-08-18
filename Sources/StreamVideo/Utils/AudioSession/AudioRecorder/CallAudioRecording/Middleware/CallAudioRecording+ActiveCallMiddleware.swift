//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    /// Middleware that synchronizes audio recording with the active call
    /// state.
    ///
    /// This middleware monitors the active call and its audio settings,
    /// automatically enabling or disabling recording based on whether
    /// the user's microphone is enabled during the call.
    ///
    /// ## Behavior
    ///
    /// - When a call becomes active, monitors its audio settings
    /// - When audio is enabled in the call, triggers recording
    /// - When the call ends, stops monitoring audio settings
    final class ActiveCallMiddleware: Middleware<CallAudioRecording>, @unchecked Sendable {
        /// The main StreamVideo instance for accessing call state.
        @Injected(\.streamVideo) private var streamVideo

        /// Container for managing subscription lifecycles.
        private let disposableBag = DisposableBag()
        
        /// Subscription to monitor active call changes.
        private var activeCallCancellable: AnyCancellable?
        
        /// Subscription to monitor call audio settings.
        private var callSettingsCancellable: AnyCancellable?

        /// Initializes the middleware and sets up active call monitoring.
        override init() {
            super.init()

            // Monitor changes to the active call
            activeCallCancellable = streamVideo
                .state
                .$activeCall
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in await self?.didUpdate($0) }
        }

        // MARK: - Private Helpers

        /// Handles changes to the active call.
        ///
        /// When a call becomes active, starts monitoring its audio settings.
        /// When the call ends, stops monitoring and cleans up subscriptions.
        ///
        /// - Parameter activeCall: The currently active call, or `nil` if no
        ///   call is active.
        private func didUpdate(_ activeCall: Call?) async {
            if let activeCall {
                callSettingsCancellable?.cancel()

                callSettingsCancellable = await activeCall
                    .state
                    .$callSettings
                    .map(\.audioOn)
                    .sink { [weak self] in self?.dispatcher?(.setShouldRecord($0)) }
            } else {
                callSettingsCancellable?.cancel()
                callSettingsCancellable = nil
            }
        }
    }
}
