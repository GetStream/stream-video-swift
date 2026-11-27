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
/// plays HLS creates the player and starts its stats reporting. The adapter
/// frees it when the call leaves HLS, and when the controller tears the call
/// down. Freeing sends the final stats.
///
/// Only the members that touch the player or the call state run on the main
/// actor, because `AVPlayer` and `CallState` live there. So a request never
/// interleaves with a change of the playback type.
final class HLSStateAdapter: Sendable {

    private let makePlayer: @MainActor (URL) -> HLSPlayer
    @MainActor private var player: HLSPlayer?
    @MainActor private var stats: HLSStatsAdapter?
    @MainActor private var url: URL?
    @MainActor private var observers: [AnyCancellable] = []

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    init(
        makePlayer: @escaping @MainActor (URL) -> HLSPlayer = { url in
            HLSPlayer(playerItem: AVPlayerItem(url: url))
        }
    ) {
        self.makePlayer = makePlayer
    }

    /// The player of the call. Returns nil unless the call plays HLS, and
    /// while the host is not live: the call is backstage, or its HLS
    /// broadcast stopped.
    ///
    /// The first call creates the player. Repeated calls return the same
    /// player, until the call moves to another playlist URL.
    @MainActor
    func player(for call: Call) -> HLSPlayer? {
        guard case let .hls(url) = call.state.playbackType else { return nil }
        observePlaybackType(of: call)
        guard !call.state.backstage, !call.state.hlsBroadcastingStopped else { return nil }
        return player(for: url, call: call)
    }

    /// Stops and forgets the player.
    ///
    /// With stats reporting, the player stops after the final read of its
    /// item, a moment later. That read does not wait for the network.
    @MainActor
    func free() {
        let player = player
        let stats = stats
        self.player = nil
        self.stats = nil
        url = nil
        guard let stats else {
            player?.invalidate()
            return
        }
        // The player keeps its item while the final stats are read. Mute it
        // so a new player does not play over it.
        player?.isMuted = true
        Task {
            await stats.stopReporting()
            player?.invalidate()
        }
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
        // Reporting reads the state of the player when it starts, so it
        // can start after the player plays. Creation does not wait for it.
        let stats = call.callController.makeHLSStatsAdapter(player: player, call: call)
        if let stats {
            Task { await stats.startReporting() }
        }
        // A new player has rate 0. Nothing else starts it.
        player.play()
        self.player = player
        self.stats = stats
        self.url = url
        return player
    }

    /// A change to WebRTC means the player has no use, and so does the end of
    /// the live: the host went backstage, or stopped the HLS broadcast.
    /// Another playlist URL replaces the player, if there is one. The
    /// subscriptions see the values in state too.
    @MainActor
    private func observePlaybackType(of call: Call) {
        guard observers.isEmpty else { return }
        observers = [
            call.state
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
                },
            call.state
                .$backstage
                .removeDuplicates()
                .filter { $0 }
                .sink { [weak self] _ in MainActor.assumeIsolated { self?.free() } },
            call.state
                .$hlsBroadcastingStopped
                .removeDuplicates()
                .filter { $0 }
                .sink { [weak self] _ in MainActor.assumeIsolated { self?.free() } }
        ]
    }
}
