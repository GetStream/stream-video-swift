//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the origin of a participant's media.
/// Values mirror the backend model. Use this to handle WebRTC users, SIP
/// gateways, and ingest streams differently.
public enum ParticipantSource: CustomStringConvertible, Hashable, Sendable {

    /// WebRTC participant. Default for SDK users.
    case webRTCUnspecified
    /// RTMP ingest source.
    case rtmp
    /// WHIP published source.
    case whip
    /// SIP gateway participant.
    case sip
    /// RTSP stream source.
    case rtsp
    /// SRT stream source.
    case srt
    /// Backend value not recognized by this SDK.
    case unrecognized(Int)

    /// Creates a `ParticipantSource` from the backend enum.
    /// Unknown values are preserved as `.unrecognized(_:)`.
    init(_ source: Stream_Video_Sfu_Models_ParticipantSource) {
        switch source {
        case .webrtcUnspecified:
            self = .webRTCUnspecified
        case .rtmp:
            self = .rtmp
        case .whip:
            self = .whip
        case .sip:
            self = .sip
        case .rtsp:
            self = .rtsp
        case .srt:
            self = .srt
        case let .UNRECOGNIZED(value):
            self = .unrecognized(value)
        }
    }

    /// Integer that matches the backend enum value.
    var rawValue: Int {
        switch self {
        case .webRTCUnspecified:
            return 0
        case .rtmp:
            return 1
        case .whip:
            return 2
        case .sip:
            return 3
        case .rtsp:
            return 4
        case .srt:
            return 5
        case let .unrecognized(value):
            return value
        }
    }

    /// Human-readable case name for logs and debugging.
    public var description: String {
        switch self {
        case .webRTCUnspecified:
            return ".webRTCUnspecified"
        case .rtmp:
            return ".rtmp"
        case .whip:
            return ".whip"
        case .sip:
            return ".sip"
        case .rtsp:
            return ".rtsp"
        case .srt:
            return ".srt"
        case let .unrecognized(value):
            return ".unrecognized(\(value))"
        }
    }
}
