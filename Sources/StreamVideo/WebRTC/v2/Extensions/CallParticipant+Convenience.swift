//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallParticipant {

    var trackSubscriptionDetails: [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        var result = [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]()
        if hasVideo {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    size: trackSize,
                    type: .video
                )
            )
        }

        if hasAudio {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .audio
                )
            )
        }

        if isScreensharing {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .screenShare
                )
            )
        }

        return result
    }
}
