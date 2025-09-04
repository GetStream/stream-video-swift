//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Handles AVAudioSession interruptions for `RTCAudioStore`.
    ///
    /// This class listens for audio session interruption events and updates the `RTCAudioStore` state accordingly.
    /// It manages the audio session's interruption state, audio enablement, and session activation.
    /// When an interruption begins, it disables audio and marks the session as interrupted.
    /// When the interruption ends, it optionally resumes the session by restoring the audio session category,
    /// mode, and options, with appropriate delays to ensure smooth recovery.
    final class InterruptionEffect: NSObject, RTCAudioSessionDelegate, @unchecked Sendable {

        /// The audio session instance used to observe interruption events.
        private let session: AudioSessionProtocol
        /// A weak reference to the `RTCAudioStore` to dispatch state changes.
        private weak var store: RTCAudioStore?
        private let disposableBag = DisposableBag()

        /// Creates a new `InterruptionEffect` that listens to the given `RTCAudioStore`'s audio session.
        ///
        /// - Parameter store: The `RTCAudioStore` instance whose session interruptions will be handled.
        /// The effect registers itself as a delegate of the store's audio session.
        init(_ store: RTCAudioStore) {
            session = store.session
            self.store = store
            super.init()

            session.add(self)
        }

        deinit {
            session.remove(self)
        }

        // MARK: - RTCAudioSessionDelegate

        /// Called when the audio session begins an interruption.
        ///
        /// Updates the store to indicate the audio session is interrupted and disables audio.
        /// - Parameter session: The audio session that began the interruption.
        func audioSessionDidBeginInterruption(_ session: RTCAudioSession) {
            store?.dispatch(.audioSession(.isInterrupted(true)))
            store?.dispatch(.audioSession(.isAudioEnabled(false)))
        }

        /// Called when the audio session ends an interruption.
        ///
        /// Updates the store to indicate the interruption ended. If the session should resume,
        /// it disables audio and session activation briefly, then restores the audio session category,
        /// mode, and options with delays, before re-enabling audio and activating the session.
        ///
        /// - Note: The delay is necessary as CallKit and AVAudioSession together are racey and we
        /// need to ensure that our configuration will go through without other parts of the app making
        /// changes later on.
        ///
        /// - Parameters:
        ///   - session: The audio session that ended the interruption.
        ///   - shouldResumeSession: A Boolean indicating whether the audio session should resume.
        func audioSessionDidEndInterruption(
            _ session: RTCAudioSession,
            shouldResumeSession: Bool
        ) {
            guard let store else {
                return
            }

            store.dispatch(.audioSession(.isInterrupted(false)))
            if shouldResumeSession {
                Task(disposableBag: disposableBag) {
                    log.debug(
                        "AudioSession will restarting...",
                        subsystems: .audioSession
                    )
                    _ = try await store.restartAudioSessionSync()
                    log.debug(
                        "AudioSession restart completed.",
                        subsystems: .audioSession
                    )
                }
            }
        }
    }
}
