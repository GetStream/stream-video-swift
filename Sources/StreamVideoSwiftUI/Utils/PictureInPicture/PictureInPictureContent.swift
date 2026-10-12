//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
            return "type=inactive"
        case let .participant(call, participant, track):
            return "type=participant cid=\(String(reflecting: call?.cId ?? "none")) participantSessionId=\(String(reflecting: participant.sessionId)) trackId=\(String(reflecting: track?.trackId ?? "none"))"
        case let .screenSharing(call, participant, track):
            return "type=screenSharing cid=\(String(reflecting: call?.cId ?? "none")) participantSessionId=\(String(reflecting: participant.sessionId)) trackId=\(String(reflecting: track.trackId))"
        case .reconnecting:
            return "type=reconnecting"
        }
    }

    static func == (
        lhs: PictureInPictureContent,
        rhs: PictureInPictureContent
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive):
            return true

        case (let .participant(lhsCall, lhsParticipant, lhsTrack), let .participant(rhsCall, rhsParticipant, rhsTrack)):
            return lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (let .screenSharing(lhsCall, lhsParticipant, lhsTrack), let .screenSharing(rhsCall, rhsParticipant, rhsTrack)):
            return lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (.reconnecting, .reconnecting):
            return true

        default:
            return false
        }
    }
}
