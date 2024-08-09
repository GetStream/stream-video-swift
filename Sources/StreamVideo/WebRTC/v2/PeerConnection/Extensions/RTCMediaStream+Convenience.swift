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
        if streamId.hasSuffix(screenShareTrackType) {
            return .screenshare
        } else if streamId.hasSuffix(videoTrackType) {
            return .video
        } else if streamId.hasSuffix(audioTrackType) {
            return .audio
        } else {
            return .unknown
        }
    }

    var trackId: String {
        streamId.components(separatedBy: ":").first ?? streamId
    }
}
