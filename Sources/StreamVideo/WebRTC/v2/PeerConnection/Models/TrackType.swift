//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents the type of media track in a WebRTC communication.
struct TrackType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    /// The raw string value of the track type.
    let rawValue: String

    /// Initializes a TrackType with the given raw value.
    ///
    /// - Parameter rawValue: The string representation of the track type.
    init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Initializes a TrackType with a string literal.
    ///
    /// - Parameter value: The string literal representation of the track type.
    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension TrackType {
    /// Represents an audio track.
    static let audio: Self = "audio"
    /// Represents a video track.
    static let video: Self = "video"
    /// Represents a screen sharing track.
    static let screenshare: Self = "screenshare"
    /// Represents an unknown track type.
    static let unknown: Self = "unknown"
}
