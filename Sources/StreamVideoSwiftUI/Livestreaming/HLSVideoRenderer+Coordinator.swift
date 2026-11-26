//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo
import SwiftUI
import UIKit

extension HLSVideoRenderer.Representable {

    /// Owns the claim on the shared player for one renderer.
    @MainActor
    final class Coordinator {

        private var call: Call
        private var playback: HLSPlayback
        private weak var view: HLSPlayerView?
        private var playbackTypeObserver: AnyCancellable?
        /// Called after a new player is shown. Lets the owner apply state,
        /// such as mute, that a player created earlier would not have.
        private let onPlayerReady: (@MainActor () async -> Void)?
        private var playbackUpdate: Task<Void, Never>?

        init(
            call: Call,
            onPlayerReady: (@MainActor () async -> Void)? = nil
        ) {
            self.call = call
            playback = HLSPlayback(call: call)
            self.onPlayerReady = onPlayerReady
        }

        func attach(to view: HLSPlayerView) {
            self.view = view
            observePlaybackType()
        }

        /// Follows `call` when the view is given another one.
        func update(call newCall: Call) {
            guard newCall.cId != call.cId else { return }
            playbackTypeObserver = nil
            call = newCall
            // Runs after an acquire in flight, so that claim is released too.
            enqueue { [self] in
                await playback.release()
                view?.player = nil
                playback = HLSPlayback(call: call)
                observePlaybackType()
            }
        }

        func dismantle() {
            playbackTypeObserver = nil
            // Captures self, so the claim is released even after the owner
            // has gone.
            enqueue { [self] in
                await playback.release()
                view?.player = nil
            }
        }

        private func observePlaybackType() {
            playbackTypeObserver = call.state
                .$playbackType
                .removeDuplicates()
                .sink { [weak self] playbackType in
                    self?.enqueue { await self?.update(for: playbackType) }
                }
        }

        private func enqueue(_ operation: @escaping @MainActor () async -> Void) {
            let previous = playbackUpdate
            playbackUpdate = Task { @MainActor in
                await previous?.value
                await operation()
            }
        }

        private func update(for playbackType: PlaybackType) async {
            switch playbackType {
            case .hls:
                let previous = view?.player
                let player = await playback.acquire()
                view?.player = player
                if player != nil, player !== previous { await onPlayerReady?() }
            case .webRTC:
                await playback.release()
                view?.player = nil
            }
        }
    }
}
