//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Middleware that keeps recording state aligned with call context,
    /// audio‑session activity, and recording permission.
    ///
    /// It observes the active call to scope monitoring, then combines:
    /// the call's `audioOn`, the audio session's `isActive`, and the
    /// recorder's permission status. Recording is enabled only when all
    /// conditions are satisfied.
    ///
    /// ## Behavior
    ///
    /// - On call activation, starts monitoring the three conditions.
    /// - Enables recording when `audioOn && isActive && hasPermission`.
    /// - Disables recording when any condition becomes false.
    /// - On call end, stops monitoring and disables recording.
    final class ShouldRecordMiddleware: Middleware<StreamCallAudioRecorder.Namespace>, @unchecked Sendable {
        /// Access to call state and `activeCall`.
        @Injected(\.streamVideo) private var streamVideo
        /// Access to audio session state and recording permission.
        @Injected(\.audioStore) private var audioStore

        /// Container for managing subscription lifecycles.
        private let disposableBag = DisposableBag()
        
        /// Monitors active call changes.
        private var activeCallCancellable: AnyCancellable?
        
        /// Monitors combined conditions that control recording.
        private var aggregatedCancellable: AnyCancellable?

        /// Sets up monitoring of the active call lifecycle.
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
        /// When a call becomes active, subscribes to call `audioOn`, audio
        /// session `isActive`, and recording permission, enabling recording
        /// only when all are true. Cleans up and disables recording when the
        /// call ends.
        ///
        /// - Parameter activeCall: The current active call, or `nil` when
        ///   there is no active call.
        private func didUpdate(_ activeCall: Call?) async {
            if let activeCall {
                aggregatedCancellable?.cancel()

                let audioOnPublisher = await activeCall
                    .state
                    .$callSettings
                    .map(\.audioOn)
                    .removeDuplicates()
                    .eraseToAnyPublisher()

                let isAudioSessionActivePublisher = audioStore
                    .publisher(\.isActive)
                    .eraseToAnyPublisher()

                let hasPermissionPublisher = audioStore
                    .publisher(\.hasRecordingPermission)
                    .eraseToAnyPublisher()

                aggregatedCancellable = Publishers
                    .CombineLatest3(audioOnPublisher, isAudioSessionActivePublisher, hasPermissionPublisher)
                    .log(.debug) {
                        "Store identifier:\(StreamCallAudioRecorder.Namespace.identifier) received audioOn:\($0) isAudioSessionActive:\($1) hasPermission:\($2)."
                    }
                    .map { $0 && $1 && $2 }
                    .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                    .sink { [weak self] in self?.dispatcher?.dispatch(.setShouldRecord($0)) }
            } else {
                guard aggregatedCancellable != nil else {
                    return
                }

                aggregatedCancellable?.cancel()
                aggregatedCancellable = nil
                dispatcher?.dispatch(.setShouldRecord(false))
            }
        }
    }
}
