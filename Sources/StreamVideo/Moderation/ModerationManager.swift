//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coordinates moderation actions such as applying video filters.
public final class ModerationManager {

    let video: VideoAdapter

    init(_ call: Call) {
        self.video = .init(call)
    }

    // MARK: - Interaction

    /// Stores a caller-selected filter so it can be restored post-moderation.
    func setVideoFilter(_ videoFilter: VideoFilter?) {
        video.didUpdateVideoFilter(videoFilter)
    }

    /// Overrides the current policy used when moderation events fire.
    public func setVideoPolicy(_ policy: VideoPolicy) {
        video.didUpdateFilterPolicy(policy)
    }
}
