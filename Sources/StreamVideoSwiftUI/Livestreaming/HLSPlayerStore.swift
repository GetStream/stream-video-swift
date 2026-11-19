//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@_spi(StreamVideo) import StreamVideo

/// Keeps one `AVPlayer` per call, so every renderer and control of the same
/// HLS call share it.
@MainActor
final class HLSPlayerStore {

    private struct Entry {
        let player: AVPlayer
        var tracking: (any HLSPlaybackTracking)?
        var leaseIds: Set<UUID>
        let playbackTypeObserver: AnyCancellable
    }

    private let makePlayer: (URL) -> AVPlayer
    private let senderForCall: (Call) -> (any HLSStatsSending)?
    private var entries: [String: Entry] = [:]

    /// The number of calls that have a player.
    var activePlayerCount: Int { entries.count }

    /// - Parameters:
    ///   - makePlayer: Builds the player for a playlist URL.
    ///   - senderForCall: Replaces the call's API client. Tests use it to
    ///     record reports. Nil uses the call's own client.
    init(
        makePlayer: @escaping (URL) -> AVPlayer = {
            AVPlayer(playerItem: AVPlayerItem(url: $0))
        },
        senderForCall: @escaping (Call) -> (any HLSStatsSending)? = { _ in nil }
    ) {
        self.makePlayer = makePlayer
        self.senderForCall = senderForCall
    }

    /// The player of the call, if it has one.
    func player(for call: Call) -> AVPlayer? {
        entries[call.cId]?.player
    }

    /// Takes a claim on the player of the call. The first claim creates the
    /// player and starts it.
    /// - Parameter playbackType: The playback type to act on. The caller
    ///   passes the value its subscription emitted, because the state of the
    ///   call does not hold it yet when the subscription runs.
    /// - Returns: `nil` unless `playbackType` is HLS.
    func acquire(for call: Call, playbackType: PlaybackType) -> HLSPlayerLease? {
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
            let tracking = makeHLSPlaybackTracking(
                player: player,
                call: call,
                sender: senderForCall(call)
            )
            lease = HLSPlayerLease(player: player, callId: callId, store: self)
            entries[callId] = Entry(
                player: player,
                tracking: tracking,
                leaseIds: [lease.leaseId],
                // The player has no use once the call stops playing HLS.
                playbackTypeObserver: call.state
                    .$playbackType
                    .filter { $0 == .webRTC }
                    .sink { [weak self] _ in self?.free(callId: callId) }
            )
            Task { await tracking?.start() }
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

    private func free(callId: String) {
        guard let entry = entries.removeValue(forKey: callId) else { return }
        entry.tracking?.stop()
        entry.player.pause()
        entry.player.replaceCurrentItem(with: nil)
    }
}

/// - Note: Matches the compiler split used by ``VideoRendererPool``.
#if compiler(>=6.0)
extension HLSPlayerStore: @preconcurrency InjectionKey {
    @MainActor
    static var currentValue: HLSPlayerStore = .init()
}
#else
extension HLSPlayerStore: InjectionKey {
    @MainActor
    static var currentValue: HLSPlayerStore = .init()
}
#endif

extension InjectedValues {
    /// The player store the HLS views use.
    var hlsPlayerStore: HLSPlayerStore {
        get { Self[HLSPlayerStore.self] }
        set { Self[HLSPlayerStore.self] = newValue }
    }
}
