//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents the type of media track in a WebRTC communication.
public struct TrackType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral, Sendable {
    /// The raw string value of the track type.
    public let rawValue: String

    /// Initializes a TrackType with the given raw value.
    ///
    /// - Parameter rawValue: The string representation of the track type.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Initializes a TrackType with a string literal.
    ///
    /// - Parameter value: The string literal representation of the track type.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    init(_ source: Stream_Video_Sfu_Models_TrackType) {
        switch source {
        case .audio:
            self = .audio
        case .video:
            self = .video
        case .screenShare:
            self = .screenshare
        default:
            self = .unknown
        }
    }
}

extension TrackType {
    /// Represents an audio track.
    public static let audio: Self = "audio"
    /// Represents a video track.
    public static let video: Self = "video"
    /// Represents a screen sharing track.
    public static let screenshare: Self = "screenshare"
    /// Represents an unknown track type.
    static let unknown: Self = "unknown"
}
