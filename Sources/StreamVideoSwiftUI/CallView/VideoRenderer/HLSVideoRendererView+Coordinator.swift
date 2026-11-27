//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo
import SwiftUI
import UIKit

/// Extension for `HLSVideoRendererView` to define the `Coordinator` class.
extension HLSVideoRendererView {

    /// A class to coordinate the `HLSVideoRendererView` and show the player
    /// of the call.
    @MainActor
    public final class Coordinator {

        private var call: Call
        private weak var view: HLSPlayerView?
        private var playbackTypeObserver: AnyCancellable?
        /// The latest request for the player. A result that comes after
        /// another change is dropped.
        private var playerRequest: Task<Void, Never>?

        init(call: Call) {
            self.call = call
        }

        func attach(to view: HLSPlayerView) {
            self.view = view
            observePlaybackType()
        }

        /// Follows `call` when the view is given another one.
        func update(call newCall: Call) {
            guard newCall !== call else { return }
            call = newCall
            clear()
            observePlaybackType()
        }

        func dismantle() {
            playbackTypeObserver = nil
            clear()
        }

        /// Follows the playback type of the same call. It is `.webRTC` until
        /// the join response grants HLS, and it returns to `.webRTC` when the
        /// call ends. The view can stay on screen through both changes, for
        /// example while it shows the view before the join completes.
        private func observePlaybackType() {
            playbackTypeObserver = call.state
                .$playbackType
                .removeDuplicates()
                .sink { [weak self] in self?.show($0) }
        }

        private func show(_ playbackType: PlaybackType) {
            clear()
            guard case .hls = playbackType else { return }
            let call = call
            playerRequest = Task { [weak self] in
                let player = await call.hlsPlayer()
                guard !Task.isCancelled else { return }
                self?.view?.player = player
            }
        }

        private func clear() {
            playerRequest?.cancel()
            playerRequest = nil
            view?.player = nil
        }
    }
}
