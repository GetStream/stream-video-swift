//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails {
    init(
        for userId: String,
        sessionId: String,
        size: CGSize? = nil,
        type: Stream_Video_Sfu_Models_TrackType
    ) {
        userID = userId
        dimension = size.map { Stream_Video_Sfu_Models_VideoDimension($0) } ?? Stream_Video_Sfu_Models_VideoDimension()
        sessionID = sessionId
        trackType = type
    }
}
