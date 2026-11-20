//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Keeps one `AVPlayer` per call, so every renderer and control of the same
/// HLS call share it.
package actor HLSPlayerStore: HLSPlayerStoring {
    private struct Entry {
        let player: AVPlayer
        var stats: HLSStatsAdapter?
        var leaseIds: Set<UUID>
        let playbackTypeObserver: AnyCancellable
    }

    private let makePlayer: @Sendable (URL) -> AVPlayer
    private var entries: [String: Entry] = [:]

    /// The number of calls that have a player.
    var activePlayerCount: Int { entries.count }

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    ///   The closure runs on the main actor.
    init(
        makePlayer: @escaping @Sendable (URL) -> AVPlayer = { url in
            AVPlayer(playerItem: AVPlayerItem(url: url))
        }
    ) {
        self.makePlayer = makePlayer
    }

    /// The player of the call, if it has one.
    package func player(for call: Call) -> AVPlayer? {
        entries[call.cId]?.player
    }

    /// Takes a claim on the player of the call. The first claim creates the
    /// player and starts it.
    /// - Parameter playbackType: The playback type to act on. The caller
    ///   passes the value its subscription emitted, because the state of the
    ///   call does not hold it yet when the subscription runs.
    /// - Returns: `nil` unless `playbackType` is HLS.
    package func acquire(
        for call: Call,
        playbackType: PlaybackType
    ) async -> (any HLSPlayerLeasing)? {
        guard case let .hls(url) = playbackType else {
            return nil
        }

        let callId = call.cId
        if var entry = entries[callId] {
            let lease = HLSPlayerLease(
                player: entry.player,
                callId: callId,
                store: self
            )
            entry.leaseIds.insert(lease.leaseId)
            entries[callId] = entry
            return lease
        }

        let player = await MainActor.run {
            let player = makePlayer(url)
            // A new player has rate 0. Nothing else starts it.
            player.play()
            return player
        }
        // Another claim created the player while this one was on the main actor.
        if entries[callId] != nil {
            await MainActor.run {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
            return await acquire(for: call, playbackType: playbackType)
        }

        let stats = await call.callController.hlsCoordinator.reportingAdapter(
            player: player,
            call: call
        )
        if entries[callId] != nil {
            await MainActor.run {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
            return await acquire(for: call, playbackType: playbackType)
        }

        let lease = HLSPlayerLease(player: player, callId: callId, store: self)
        let observer = await MainActor.run {
            // Skip the value already in state. A later change to WebRTC
            // means the player has no use.
            call.state
                .$playbackType
                .dropFirst()
                .filter { $0 == .webRTC }
                .sink { _ in
                    Task { await self.free(callId: callId) }
                }
        }
        entries[callId] = Entry(
            player: player,
            stats: stats,
            leaseIds: [lease.leaseId],
            playbackTypeObserver: observer
        )
        await stats?.startReporting()
        return lease
    }

    func release(leaseId: UUID, callId: String) async {
        guard var entry = entries[callId], entry.leaseIds.remove(leaseId) != nil else {
            return
        }
        if entry.leaseIds.isEmpty {
            await free(callId: callId)
        } else {
            entries[callId] = entry
        }
    }

    private func free(callId: String) async {
        guard let entry = entries.removeValue(forKey: callId) else { return }
        entry.stats?.stopReporting()
        let player = entry.player
        await MainActor.run {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }
}

extension HLSPlayerStore: InjectionKey {
    package nonisolated(unsafe) static var currentValue: HLSPlayerStore = .init()
}

extension InjectedValues {
    /// The player store the HLS views use.
    package var hlsPlayerStore: any HLSPlayerStoring {
        get { Self[HLSPlayerStore.self] }
        set {
            guard let store = newValue as? HLSPlayerStore else { return }
            Self[HLSPlayerStore.self] = store
        }
    }
}
