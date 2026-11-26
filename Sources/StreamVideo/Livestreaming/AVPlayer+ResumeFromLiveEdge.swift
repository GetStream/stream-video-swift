//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVPlayer {

    /// Resumes a live stream from the live edge.
    ///
    /// A paused live stream falls behind, and its window can slide past the
    /// paused position, so playback restarts near the end of the seekable
    /// range.
    @MainActor
    func resumeFromLiveEdge() {
        if
            let item = currentItem,
            let range = item.seekableTimeRanges.last?.timeRangeValue,
            let target = liveEdgeTarget(
                in: range,
                recommendedOffset: item.recommendedTimeOffsetFromLive
            ) {
            seek(to: target)
        }
        play()
    }

    /// Where a resumed live stream starts: the recommended distance from the
    /// live edge, kept inside the seekable range.
    /// - Returns: `nil` when the range is not usable.
    private func liveEdgeTarget(
        in range: CMTimeRange,
        recommendedOffset: CMTime
    ) -> CMTime? {
        guard range.isValid, !range.isEmpty else { return nil }
        guard recommendedOffset.isNumeric else { return range.end }
        let target = CMTimeSubtract(range.end, recommendedOffset)
        return CMTimeMaximum(target, range.start)
    }
}
