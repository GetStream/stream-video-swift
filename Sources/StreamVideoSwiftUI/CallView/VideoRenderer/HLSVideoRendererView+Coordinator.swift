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

        @Injected(\.pictureInPictureAdapter) private var pictureInPictureAdapter

        private var call: Call
        private weak var view: HLSPlayerView?
        private var playbackTypeObserver: AnyCancellable?
        /// The latest request for the player. A result that comes after
        /// another change is dropped.
        private var playerRequest: Task<Void, Never>?
        /// The layer registered with Picture in Picture. The view can be gone
        /// before the teardown runs, so the coordinator keeps the layer.
        private var registeredLayer: AVPlayerLayer?

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
            unregisterPlayerLayer()
            call = newCall
            clear()
            observePlaybackType()
        }

        func dismantle() {
            playbackTypeObserver = nil
            unregisterPlayerLayer()
            clear()
        }

        /// Follows the playback type of the same call. It is `.webRTC` until
        /// the join response grants HLS, and it returns to `.webRTC` when the
        /// call ends. The view can stay on screen through both changes, for
        /// example while it shows the view before the join completes.
        ///
        /// It follows the backstage flag too. The SDK stops the player when
        /// the call goes backstage, and the view asks again when the host
        /// returns, even with the same playlist URL. A new HLS broadcast has
        /// a new URL, which the playback type follows.
        private func observePlaybackType() {
            let state = call.state
            playbackTypeObserver = Publishers
                .CombineLatest(state.$playbackType, state.$backstage)
                .removeDuplicates { $0 == $1 }
                .sink { [weak self] playbackType, isBackstage in
                    self?.show(playbackType, isLive: !isBackstage)
                }
        }

        private func show(_ playbackType: PlaybackType, isLive: Bool) {
            playerRequest?.cancel()
            playerRequest = nil
            // A new playlist URL keeps the old player on the view until the
            // new one arrives, so an active Picture-in-Picture layer never
            // goes empty. Leaving HLS, or the live, clears it at once.
            guard case .hls = playbackType, isLive else {
                view?.player = nil
                unregisterPlayerLayer()
                return
            }
            let call = call
            // A call change during the request must not move the layer.
            let callId = call.cId
            playerRequest = Task { [weak self] in
                let player = await call.hlsPlayer()
                guard !Task.isCancelled else { return }
                self?.view?.player = player
                if player != nil { self?.registerPlayerLayer(callId: callId) }
            }
        }

        /// Lets Picture in Picture show the layer for the call of this view.
        private func registerPlayerLayer(callId: String) {
            guard let layer = view?.playerLayer else { return }
            registeredLayer = layer
            pictureInPictureAdapter.setPlayerLayer(layer, cId: callId)
        }

        /// Clears the layer, unless Picture in Picture shows another one now.
        private func unregisterPlayerLayer() {
            guard let layer = registeredLayer else { return }
            registeredLayer = nil
            pictureInPictureAdapter.removePlayerLayer(layer)
        }

        private func clear() {
            playerRequest?.cancel()
            playerRequest = nil
            view?.player = nil
        }
    }
}
