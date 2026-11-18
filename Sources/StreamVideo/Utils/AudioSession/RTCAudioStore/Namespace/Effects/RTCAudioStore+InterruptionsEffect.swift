//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Converts audio-session interruptions into ordered recovery actions.
    ///
    /// Interruption start marks the store as interrupted. A resumable end,
    /// and a non-resuming end while the app is in the foreground, clear
    /// that state and restart recording when it was active. Muted-speech
    /// detection is temporarily disabled around the restart so WebRTC
    /// rebuilds the input graph instead of treating recovery as a mute
    /// toggle.
    ///
    /// Microphone mute restoration belongs to
    /// `AudioDeviceModule.setRecording(_:)`, after native recording starts. The
    /// effect intentionally does not replay a mute snapshot that could be stale
    /// by the time its queued actions execute.
    final class InterruptionsEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let disposableBag = DisposableBag()

        convenience init(_ source: RTCAudioSession) {
            self.init(.init(source))
        }

        init(_ audioSessionObserver: RTCAudioSessionPublisher) {
            self.audioSessionObserver = audioSessionObserver
            super.init()

            audioSessionObserver
                .publisher
                .sink { [weak self] in self?.handle($0) }
                .store(in: disposableBag)
        }

        // MARK: - Private Helpers

        /// Builds and dispatches the action sequence for an audio-session event.
        ///
        /// A non-resuming end keeps the interrupted flag while the app
        /// is in the background. The later resumable end can then rebuild
        /// capture. When the app is already in the foreground, that end
        /// does not arrive, so this end recovers immediately. A recovery
        /// restarts recording only when the store was interrupted and
        /// recording was previously active. Persistent muted speech
        /// detection is restored after that restart. Mute state is not
        /// appended here because recording recovery owns post-start restoration.
        ///
        /// - Parameter event: The WebRTC audio-session event to process.
        private func handle(
            _ event: RTCAudioSessionPublisher.Event
        ) {
            switch event {
            case .didBeginInterruption:
                dispatcher?.dispatch(.setInterrupted(true))

            case .didEndInterruption(let shouldResumeSession):
                guard
                    state?.isInterrupted == true
                else {
                    return
                }

                // A non-resuming end in the background leaves the store
                // interrupted. WebRTC sends a later end when the app
                // becomes active. Clearing the flag here drops that end,
                // so the torn-down input graph is never rebuilt. In the
                // foreground this end is the last one, so recover now.
                let appIsInBackground = applicationStateAdapter.state == .background
                guard shouldResumeSession || !appIsInBackground else {
                    return
                }

                var actions: [Namespace.Action] = [
                    .setInterrupted(false)
                ]

                if
                    let state = stateProvider?(),
                    state.audioDeviceModule != nil {
                    let isRecording = state.isRecording
                    let isMutedSpeechDetectionEnabled = state.isMutedSpeechDetectionEnabled

                    if isRecording {
                        // Muted speech detection keeps WebRTC's input graph
                        // "enabled" across a stop/start (persistent recording
                        // mode), so resuming after an interruption looks like a
                        // runtime mute toggle and the engine input — torn down
                        // by the OS during the interruption — is never actually
                        // restarted, leaving capture dead. Drop persistent mode
                        // around the restart so the input-graph transition
                        // forces a real engine restart, then restore it.
                        if isMutedSpeechDetectionEnabled {
                            actions.append(.setMutedSpeechDetectionEnabled(false))
                        }
                        actions.append(.setRecording(false))
                        actions.append(.setRecording(true))
                        if isMutedSpeechDetectionEnabled {
                            actions.append(.setMutedSpeechDetectionEnabled(true))
                        }
                    }
                }
                dispatcher?.dispatch(actions.map(\.box))
            default:
                break
            }
        }
    }
}
