//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC

/// Content state for Picture-in-Picture window during video calls.
enum PictureInPictureContent: Equatable, CustomStringConvertible {
    /// Picture-in-Picture window is not active.
    case inactive

    /// Shows a participant's video feed in Picture-in-Picture.
    ///
    /// - Parameters:
    ///   - call: Current call instance
    ///   - participant: Participant being displayed
    ///   - track: Video track to render
    case participant(Call?, CallParticipant, RTCVideoTrack?)

    /// Shows a participant's screen share in Picture-in-Picture.
    ///
    /// - Parameters:
    ///   - call: Current call instance
    ///   - participant: Participant sharing screen
    ///   - track: Screen sharing track
    case screenSharing(Call?, CallParticipant, RTCVideoTrack)

    /// Picture-in-Picture window is reconnecting to the call.
    case reconnecting

    var description: String {
        switch self {
        case .inactive:
            ".inactive"
        case let .participant(call, participant, track):
            ".participant(cId:\(call?.cId ?? "-"), name:\(participant.name), track:\(track?.trackId ?? "-"))"
        case let .screenSharing(call, participant, track):
            ".screenSharing(cId:\(call?.cId ?? "-"), name:\(participant.name), track:\(track.trackId))"
        case .reconnecting:
            ".reconnecting"
        }
    }

    static func == (
        lhs: PictureInPictureContent,
        rhs: PictureInPictureContent
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive):
            true

        case (let .participant(lhsCall, lhsParticipant, lhsTrack), let .participant(rhsCall, rhsParticipant, rhsTrack)):
            lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (let .screenSharing(lhsCall, lhsParticipant, lhsTrack), let .screenSharing(rhsCall, rhsParticipant, rhsTrack)):
            lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (.reconnecting, .reconnecting):
            true

        default:
            false
        }
    }
}
