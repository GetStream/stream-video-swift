//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Middleware that keeps recording state aligned with call context,
    /// audio‑session activity, and recording permission.
    ///
    /// It observes the active call of the current `StreamVideo` instance,
    /// following any replacement client, to scope monitoring, then combines:
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
        /// Access to audio session state and recording permission.
        @Injected(\.audioStore) private var audioStore

        /// Container for managing subscription lifecycles.
        private let disposableBag = DisposableBag()
        
        /// Monitors active call changes.
        private var activeCallCancellable: AnyCancellable?
        
        /// Monitors combined conditions that control recording.
        private var aggregatedCancellable: AnyCancellable?
        /// Bumps on every active-call change so a late update cannot
        /// subscribe after hang-up.
        private var callMonitoringGeneration = 0

        /// Sets up monitoring of the active call lifecycle.
        override init() {
            super.init()

            // The recorder outlives clients, so follow the current one.
            activeCallCancellable = StreamVideoProviderKey
                .publisher
                .map { streamVideo -> AnyPublisher<Call?, Never> in
                    streamVideo?.state.$activeCall.eraseToAnyPublisher()
                        ?? Just(nil).eraseToAnyPublisher()
                }
                .switchToLatest()
                // A new client reports its current call, or no call. The same
                // call, or no call, reported again is not a change.
                .removeDuplicates { $0?.cId == $1?.cId }
                // Skip "no call" reports until the first call. They can arrive
                // after the lobby started recording. After the first call,
                // every "no call" passes, so a call end turns recording off.
                .drop(while: { $0 == nil })
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
                guard let generation = await beginMonitoring(activeCall) else { return }

                let audioOnPublisher = await activeCall
                    .state
                    .$callSettings
                    .map(\.audioOn)
                    .removeDuplicates()
                    .eraseToAnyPublisher()

                // Hang-up can win while this read is in flight.
                guard await stillMonitors(activeCall, generation: generation) else {
                    return
                }

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
                await MainActor.run {
                    callMonitoringGeneration += 1
                    aggregatedCancellable?.cancel()
                    aggregatedCancellable = nil
                }
                dispatcher?.dispatch(.setShouldRecord(false))
            }
        }

        /// Starts a monitoring generation when `call` is still active.
        private func beginMonitoring(_ call: Call) async -> Int? {
            await MainActor.run {
                guard StreamVideoProviderKey.currentValue?.state.activeCall?.cId == call.cId else {
                    return nil
                }
                callMonitoringGeneration += 1
                aggregatedCancellable?.cancel()
                return callMonitoringGeneration
            }
        }

        /// `true` when hang-up has not replaced this monitoring generation.
        private func stillMonitors(_ call: Call, generation: Int) async -> Bool {
            await MainActor.run {
                generation == callMonitoringGeneration
                    && StreamVideoProviderKey.currentValue?.state.activeCall?.cId == call.cId
            }
        }
    }
}
