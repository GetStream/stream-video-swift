//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Extension providing a convenience initializer for
/// `Stream_Video_Sfu_Signal_TrackSubscriptionDetails`.
extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails {

    /// Initializes a `TrackSubscriptionDetails` instance for a specific user and session.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user associated with the track subscription.
    ///   - sessionId: The session ID for the user's subscription.
    ///   - size: The optional video dimension (`CGSize`) for the track. Defaults to `nil`.
    ///   - type: The type of track (e.g., audio, video, screen share).
    init(
        for userId: String,
        sessionId: String,
        size: CGSize? = nil,
        type: Stream_Video_Sfu_Models_TrackType
    ) {
        userID = userId
        if type == .video || type == .screenShare {
            dimension = size.map { Stream_Video_Sfu_Models_VideoDimension($0) } ?? Stream_Video_Sfu_Models_VideoDimension()
        }
        sessionID = sessionId
        trackType = type
    }
}
