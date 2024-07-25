//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

private let screenShareTrackType = "TRACK_TYPE_SCREEN_SHARE"
private let videoTrackType = "TRACK_TYPE_VIDEO"
private let audioTrackType = "TRACK_TYPE_AUDIO"

extension RTCMediaStream {
    var trackType: TrackType {
        if streamId.contains(screenShareTrackType) {
            return .screenShare
        } else if streamId.contains(videoTrackType) {
            return .video
        } else if streamId.contains(audioTrackType) {
            return .audio
        } else {
            return .unknown
        }
    }
}
