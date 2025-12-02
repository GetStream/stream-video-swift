//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Moderation {

    /// Policy describing what filter to apply and for how long.
    public struct VideoPolicy: Sendable {
        var duration: TimeInterval
        var videoFilter: VideoFilter

        /// Creates a policy that blurs video for a limited amount of time.
        public init(duration: TimeInterval, videoFilter: VideoFilter) {
            self.duration = duration
            self.videoFilter = videoFilter
        }
    }
}
