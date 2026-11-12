//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Maps the livestream controls onto the shared HLS player of a call.
///
/// The controls hold no claim on the player. They look it up on every action,
/// so they never act on a player that the store already freed.
@MainActor
final class HLSPlaybackControls {

    private let call: Call
    private let store: HLSPlayerStore

    /// The player the controls act on. `nil` while the call has none.
    var player: AVPlayer? { store.player(for: call) }

    init(call: Call, store: HLSPlayerStore = .shared) {
        self.call = call
        self.store = store
    }

    /// Mutes or unmutes the player. This does not change the call speaker.
    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    /// Pauses the player, or resumes it from the live edge.
    func setPaused(_ paused: Bool) {
        guard let player else { return }
        if paused {
            player.pause()
        } else {
            seekToLiveEdge(of: player)
            player.play()
        }
    }

    /// Where a resumed live stream starts: the recommended distance from the
    /// live edge, kept inside the seekable range.
    /// - Returns: `nil` when the range is not usable.
    static func liveEdgeTarget(
        in range: CMTimeRange,
        recommendedOffset: CMTime
    ) -> CMTime? {
        guard range.isValid, !range.isEmpty else { return nil }
        guard recommendedOffset.isNumeric else { return range.end }
        let target = CMTimeSubtract(range.end, recommendedOffset)
        return CMTimeMaximum(target, range.start)
    }

    // MARK: - Private Helpers

    /// A paused live stream falls behind, and its window can slide past the
    /// paused position, so resuming starts near the end of the seekable range.
    private func seekToLiveEdge(of player: AVPlayer) {
        guard
            let item = player.currentItem,
            let range = item.seekableTimeRanges.last?.timeRangeValue,
            let target = Self.liveEdgeTarget(
                in: range,
                recommendedOffset: item.recommendedTimeOffsetFromLive
            )
        else {
            return
        }
        player.seek(to: target)
    }
}
