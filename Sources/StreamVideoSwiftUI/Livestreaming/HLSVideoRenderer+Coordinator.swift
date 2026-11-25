//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

extension HLSVideoRenderer {

    /// Owns the claim on the shared player for one renderer.
    @MainActor
    public final class Coordinator {

        private var call: Call
        private let store: HLSPlayerStore
        private var lease: HLSPlayerLease?
        private weak var view: HLSPlayerView?
        private var playbackTypeObserver: AnyCancellable?
        /// Called after a new player is shown. Lets the owner apply state,
        /// such as mute, that a player created earlier would not have.
        private let onPlayerReady: (() -> Void)?

        init(
            call: Call,
            store: HLSPlayerStore,
            onPlayerReady: (() -> Void)? = nil
        ) {
            self.call = call
            self.store = store
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
            lease?.release()
            lease = nil
            call = newCall
            observePlaybackType()
        }

        func dismantle() {
            playbackTypeObserver = nil
            lease?.release()
            lease = nil
            view?.player = nil
        }

        private func observePlaybackType() {
            playbackTypeObserver = call.state
                .$playbackType
                .removeDuplicates()
                .sink { [weak self] in self?.update(for: $0) }
        }

        private func update(for playbackType: PlaybackType) {
            switch playbackType {
            case .hls:
                guard lease == nil else { return }
                lease = store.acquire(for: call, playbackType: playbackType)
                view?.player = lease?.player
                if lease != nil { onPlayerReady?() }
            case .webRTC:
                lease?.release()
                lease = nil
                view?.player = nil
            }
        }
    }
}
