//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Keeps one `AVPlayer` per call, so every renderer and control of the same
/// HLS call share it.
@MainActor
public final class HLSPlayerStore {
    private struct Entry {
        let player: AVPlayer
        var stats: HLSStatsAdapter?
        var leaseIds: Set<UUID>
        let playbackTypeObserver: AnyCancellable
    }

    private let makePlayer: (URL) -> AVPlayer
    private var entries: [String: Entry] = [:]

    /// The number of calls that have a player.
    var activePlayerCount: Int { entries.count }

    /// - Parameter makePlayer: Builds the player for a playlist URL.
    public init(
        makePlayer: @escaping (URL) -> AVPlayer = {
            AVPlayer(playerItem: AVPlayerItem(url: $0))
        }
    ) {
        self.makePlayer = makePlayer
    }

    /// The player of the call, if it has one.
    public func player(for call: Call) -> AVPlayer? {
        entries[call.cId]?.player
    }

    /// Takes a claim on the player of the call. The first claim creates the
    /// player and starts it.
    /// - Parameter playbackType: The playback type to act on. The caller
    ///   passes the value its subscription emitted, because the state of the
    ///   call does not hold it yet when the subscription runs.
    /// - Returns: `nil` unless `playbackType` is HLS.
    public func acquire(for call: Call, playbackType: PlaybackType) -> HLSPlayerLease? {
        guard case let .hls(url) = playbackType else {
            return nil
        }

        let callId = call.cId
        let lease: HLSPlayerLease
        if var entry = entries[callId] {
            lease = HLSPlayerLease(player: entry.player, callId: callId, store: self)
            entry.leaseIds.insert(lease.leaseId)
            entries[callId] = entry
        } else {
            let player = makePlayer(url)
            // A new player has rate 0. Nothing else starts it.
            player.play()
            let stats = makeStats(player: player, call: call)
            lease = HLSPlayerLease(player: player, callId: callId, store: self)
            entries[callId] = Entry(
                player: player,
                stats: stats,
                leaseIds: [lease.leaseId],
                // The player has no use once the call stops playing HLS.
                playbackTypeObserver: call.state
                    .$playbackType
                    .filter { $0 == .webRTC }
                    .sink { [weak self] _ in self?.free(callId: callId) }
            )
            Task { await stats?.start() }
        }
        return lease
    }

    func release(leaseId: UUID, callId: String) {
        guard var entry = entries[callId], entry.leaseIds.remove(leaseId) != nil else {
            return
        }
        if entry.leaseIds.isEmpty {
            free(callId: callId)
        } else {
            entries[callId] = entry
        }
    }

    private func makeStats(player: AVPlayer, call: Call) -> HLSStatsAdapter? {
        let callSessionId = call.state.session?.id ?? ""
        let unifiedSessionId = call.callController.unifiedSessionId
        guard !callSessionId.isEmpty, !unifiedSessionId.isEmpty else {
            return nil
        }
        let delivery = call.callController.hlsStatsDelivering
            ?? HLSStatsDelivery(endpoints: call.coordinatorClient)
        guard let delivery else { return nil }
        let seconds = call.state.statsCollectionInterval > 0
            ? TimeInterval(call.state.statsCollectionInterval)
            : 5
        return HLSStatsAdapter(
            player: player,
            callType: call.callType,
            callId: call.callId,
            callSessionId: callSessionId,
            unifiedSessionId: unifiedSessionId,
            interval: seconds,
            delivery: delivery
        )
    }

    private func free(callId: String) {
        guard let entry = entries.removeValue(forKey: callId) else { return }
        entry.stats?.stop()
        entry.player.pause()
        entry.player.replaceCurrentItem(with: nil)
    }
}

/// - Note: Matches the compiler split used by ``VideoRendererPool``.
#if compiler(>=6.0)
extension HLSPlayerStore: @preconcurrency InjectionKey {
    @MainActor
    public static var currentValue: HLSPlayerStore = .init()
}
#else
extension HLSPlayerStore: InjectionKey {
    @MainActor
    public static var currentValue: HLSPlayerStore = .init()
}
#endif

extension InjectedValues {
    /// The player store the HLS views use.
    public var hlsPlayerStore: HLSPlayerStore {
        get { Self[HLSPlayerStore.self] }
        set { Self[HLSPlayerStore.self] = newValue }
    }
}
