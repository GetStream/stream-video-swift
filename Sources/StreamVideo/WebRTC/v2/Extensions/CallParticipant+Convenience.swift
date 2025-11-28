//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallParticipant {

    /// Generates a list of track subscription details for the current
    /// participant, based on the incoming video policy. The details include
    /// information about the participant's video, audio, and screen-sharing
    /// tracks.
    ///
    /// - Parameter incomingVideoQualitySettings: The settings that determine whether video
    ///   is allowed, manually controlled, or disabled for specific session IDs.
    /// - Returns: An array of `Stream_Video_Sfu_Signal_TrackSubscriptionDetails`
    ///   containing the participant's track details.
    func trackSubscriptionDetails(incomingVideoQualitySettings: IncomingVideoQualitySettings)
        -> [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        var result = [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]()

        /// If the participant has video and the video is not disabled by the incoming video quality settings,
        /// add the video track subscription details.
        if hasVideo, !incomingVideoQualitySettings.isVideoDisabled(for: sessionId) {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    /// If the session is covered by the incoming video quality setting, use the
                    /// target size. Otherwise, use the track's size.
                    size: incomingVideoQualitySettings.contains(sessionId) == true
                        ? incomingVideoQualitySettings.targetSize
                        : trackSize,
                    type: .video
                )
            )
        }

        /// If the participant has audio, add the audio track subscription details.
        if hasAudio {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .audio
                )
            )
        }

        /// If the participant is sharing their screen, add the screen-sharing track subscription details.
        if isScreensharing {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .screenShare
                )
            )

            /// We subscribe to screenShareAudio anytime a user is screenSharing. In the future
            /// that should be driven by events to know if the user is actually publishing audio.
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .screenShareAudio
                )
            )
        }

        return result
    }
}
