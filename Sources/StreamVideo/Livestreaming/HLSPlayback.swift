//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The public way to use a call's HLS player. Every renderer of the call
/// shares one AVPlayer. Each instance holds at most one claim on it.
///
/// Use it to build your own HLS UI when ``CallState/playbackType`` is
/// ``PlaybackType/hls(_:)``. The player lives while at least one instance
/// holds a claim. Calls can come from any thread. The player is changed on the
/// main actor.
///
/// ```swift
/// let playback = HLSPlayback(call: call)
/// let player = await playback.acquire() // nil unless the call plays HLS
/// await playback.setMuted(true)
/// await playback.release()
/// ```
///
/// - Important: This API is in beta, like ``PlaybackType``.
public final class HLSPlayback: @unchecked Sendable {

    private typealias Claim = (
        id: UUID,
        playbackType: PlaybackType,
        task: Task<AVPlayer?, Never>
    )

    private let call: Call
    private let store: HLSPlayerStore
    private let queue = UnfairQueue()
    /// The claim of this instance.
    private var claim: Claim?

    /// Creates the playback of a call.
    ///
    /// Every instance of the same call uses the same `AVPlayer`.
    /// - Parameter call: The call that plays HLS.
    public init(call: Call) {
        self.call = call
        store = InjectedValues[\.hlsPlayerStore]
    }

    init(call: Call, store: HLSPlayerStore) {
        self.call = call
        self.store = store
    }

    /// Claims the shared player. Returns nil unless the call plays HLS.
    ///
    /// Call it again when ``CallState/playbackType`` changes to `.hls`.
    /// Give the claim back with ``release()`` when your UI goes away.
    ///
    /// A repeated call while the claim is held returns the same player. A
    /// call that moved to another playlist URL gives the claim back and takes
    /// a new one, so the player loads the new stream.
    public func acquire() async -> AVPlayer? {
        // The state holds the playback type when this runs, after the
        // subscriber that asked for the claim has been notified.
        let playbackType = await MainActor.run { call.state.playbackType }
        let (claim, replaced) = currentOrNewClaim(for: playbackType)
        if let replaced { await give(back: replaced) }
        let player = await claim.task.value
        // The store frees the player when the call leaves HLS. Drop the
        // stale claim, and acquire again.
        if let player, await store.player(for: call) !== player {
            forget(claim.id)
            return await acquire()
        }
        // A call that does not play HLS yet must not keep a nil claim.
        if player == nil { forget(claim.id) }
        return player
    }

    /// Gives the claim back. The player stops when no claim is left.
    ///
    /// Waits for an acquire in flight, so its claim is released too.
    public func release() async {
        if let claim = takeClaim() { await give(back: claim) }
    }

    /// Mutes or unmutes the player. This does not change the call speaker.
    ///
    /// Does nothing when no player exists.
    public func setMuted(_ muted: Bool) async {
        let player = await store.player(for: call)
        await MainActor.run { player?.isMuted = muted }
    }

    /// Pauses, or resumes from the live edge.
    ///
    /// The player stays paused when the system would resume it, for example
    /// when the app returns to the foreground. Does nothing when no player
    /// exists.
    public func setPaused(_ paused: Bool) async {
        guard let player = await store.setPausedByUser(paused, for: call) else { return }
        await MainActor.run {
            if paused {
                player.pause()
            } else {
                player.resumeFromLiveEdge()
            }
        }
    }

    // MARK: - Private Helpers

    /// The claim for `playbackType`, and the claim it replaced.
    /// The claim is set before the first suspension, so a concurrent
    /// `acquire()` joins it instead of taking a second claim.
    private func currentOrNewClaim(
        for playbackType: PlaybackType
    ) -> (claim: Claim, replaced: Claim?) {
        queue.sync {
            if let claim, claim.playbackType == playbackType { return (claim, nil) }
            let replaced = claim
            let id = UUID()
            let task = Task { [call, store] in
                await store.acquire(for: call, claimId: id, playbackType: playbackType)
            }
            let newClaim = (id: id, playbackType: playbackType, task: task)
            claim = newClaim
            return (newClaim, replaced)
        }
    }

    /// Waits for the claim to finish, then releases it.
    private func give(back claim: Claim) async {
        _ = await claim.task.value
        await store.release(claimId: claim.id, for: call)
    }

    private func forget(_ id: UUID) {
        queue.sync {
            if claim?.id == id { claim = nil }
        }
    }

    private func takeClaim() -> Claim? {
        queue.sync {
            let taken = claim
            claim = nil
            return taken
        }
    }
}
