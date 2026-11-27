//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Owns the HLS player of a call.
///
/// The call controller owns one adapter. Every renderer and control of the
/// call reaches the same player through it. The first request while the call
/// plays HLS creates the player. The adapter frees it when the call leaves
/// HLS, and when the controller tears the call down.
///
/// Only the members that touch the player or the call state run on the main
/// actor, because `AVPlayer` and `CallState` live there. So a request never
/// interleaves with a change of the playback type.
final class HLSStateAdapter: Sendable {

    private let makePlayer: @MainActor (URL) -> HLSPlayer
    @MainActor private var player: HLSPlayer?
    @MainActor private var url: URL?
    @MainActor private var playbackTypeObserver: AnyCancellable?

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    init(
        makePlayer: @escaping @MainActor (URL) -> HLSPlayer = { url in
            HLSPlayer(playerItem: AVPlayerItem(url: url))
        }
    ) {
        self.makePlayer = makePlayer
    }

    /// The player of the call. Returns nil unless the call plays HLS.
    ///
    /// The first call creates the player. Repeated calls return the same
    /// player, until the call moves to another playlist URL.
    @MainActor
    func player(for call: Call) -> HLSPlayer? {
        guard case let .hls(url) = call.state.playbackType else { return nil }
        observePlaybackType(of: call)
        return player(for: url, call: call)
    }

    /// Stops and forgets the player.
    @MainActor
    func free() {
        player?.invalidate()
        player = nil
        url = nil
    }

    // MARK: - Private Helpers

    /// The player for `url`. Another URL replaces the player.
    @MainActor
    private func player(for url: URL, call: Call) -> HLSPlayer {
        if let player, self.url == url { return player }
        free()
        let player = makePlayer(url)
        player.startObserving(
            audioOutputOn: call.state.$callSettings.map(\.audioOutputOn).eraseToAnyPublisher()
        )
        // A new player has rate 0. Nothing else starts it.
        player.play()
        self.player = player
        self.url = url
        return player
    }

    /// A change to WebRTC means the player has no use. Another playlist URL
    /// replaces the player, if there is one. The subscription sees the value
    /// in state too.
    @MainActor
    private func observePlaybackType(of call: Call) {
        guard playbackTypeObserver == nil else { return }
        playbackTypeObserver = call.state
            .$playbackType
            .removeDuplicates()
            .sink { [weak self, weak call] playbackType in
                MainActor.assumeIsolated {
                    switch playbackType {
                    case .webRTC:
                        self?.free()
                    case let .hls(url):
                        guard let self, let call, self.player != nil else { return }
                        _ = self.player(for: url, call: call)
                    }
                }
            }
    }
}
