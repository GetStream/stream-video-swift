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
actor HLSStateAdapter {

    private struct Current {
        let url: URL
        let task: Task<HLSPlayer, Never>
    }

    private let makePlayer: @Sendable (URL) -> HLSPlayer
    private var current: Current?
    private var playbackTypeObserver: AnyCancellable?

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    ///   The closure runs on the main actor.
    init(
        makePlayer: @escaping @Sendable (URL) -> HLSPlayer = { url in
            HLSPlayer(playerItem: AVPlayerItem(url: url))
        }
    ) {
        self.makePlayer = makePlayer
    }

    /// The player of the call. Returns nil unless the call plays HLS.
    ///
    /// The first call creates the player. Concurrent and repeated calls
    /// return the same player, until the call moves to another playlist URL.
    func player(for call: Call) async -> HLSPlayer? {
        guard case let .hls(url) = await playbackType(of: call) else { return nil }
        await observePlaybackType(of: call)
        let player = await task(for: url, call: call).value
        // The call can leave HLS, or change the URL, while the player is
        // created. The observer frees the player then.
        guard current?.url == url else { return nil }
        return await playbackType(of: call) == .hls(url) ? player : nil
    }

    /// Stops and forgets the player.
    func free() async {
        playbackTypeObserver = nil
        guard let current else { return }
        self.current = nil
        await invalidate(current)
    }

    // MARK: - Private Helpers

    private func playbackType(of call: Call) async -> PlaybackType {
        await MainActor.run { call.state.playbackType }
    }

    /// The creation of the player for `url`. Another URL replaces the player.
    /// It sets the state before it suspends, so a concurrent request joins
    /// the creation instead of starting a second one.
    private func task(for url: URL, call: Call) async -> Task<HLSPlayer, Never> {
        if let current, current.url == url { return current.task }
        let replaced = current
        let task = Task { @MainActor [makePlayer] in
            let player = makePlayer(url)
            player.startObserving(
                audioOutputOn: call.state.$callSettings.map(\.audioOutputOn).eraseToAnyPublisher()
            )
            // A new player has rate 0. Nothing else starts it.
            player.play()
            return player
        }
        current = Current(url: url, task: task)
        if let replaced { await invalidate(replaced) }
        return task
    }

    /// A change to WebRTC means the player has no use. Another playlist URL
    /// replaces the player, if there is one. The subscription sees the value
    /// in state too.
    private func observePlaybackType(of call: Call) async {
        guard playbackTypeObserver == nil else { return }
        let observer = await MainActor.run {
            call.state
                .$playbackType
                .removeDuplicates()
                .sink { [weak self, weak call] playbackType in
                    Task { await self?.apply(playbackType, call: call) }
                }
        }
        if playbackTypeObserver == nil {
            playbackTypeObserver = observer
        } else {
            observer.cancel()
        }
    }

    private func apply(_ playbackType: PlaybackType, call: Call?) async {
        switch playbackType {
        case .webRTC:
            await free()
        case let .hls(url):
            guard let call, current != nil else { return }
            _ = await task(for: url, call: call)
        }
    }

    private func invalidate(_ current: Current) async {
        let player = await current.task.value
        await MainActor.run { player.invalidate() }
    }
}
