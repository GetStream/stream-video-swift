//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension HLSPlayerStore {

    /// The player of one call, and everything tied to its life.
    final class Entry {
        let url: URL
        let player: AVPlayer
        var claimIds: Set<UUID>
        /// Whether the user paused the player. The system resumes only a
        /// player the user did not pause. The resume reads it on the main
        /// actor, right before it acts, so a pause that arrives in between
        /// is not undone.
        let isPausedByUser = Atomic<Bool>(wrappedValue: false)
        let playbackTypeObserver: AnyCancellable
        /// Resumes the player when the system paused it. Freed with the entry.
        let resumeObserver: AnyCancellable

        init(
            url: URL,
            player: AVPlayer,
            claimIds: Set<UUID>,
            playbackTypeObserver: AnyCancellable,
            resumeObserver: AnyCancellable
        ) {
            self.url = url
            self.player = player
            self.claimIds = claimIds
            self.playbackTypeObserver = playbackTypeObserver
            self.resumeObserver = resumeObserver
        }
    }
}
