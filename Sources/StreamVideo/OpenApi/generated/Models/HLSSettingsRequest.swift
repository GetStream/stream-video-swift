//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class HLSSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Whether HLS broadcasting should start automatically
    public var autoOn: Bool?
    /// Whether HLS broadcasting is enabled
    public var enabled: Bool?
    /// Quality tracks for HLS. One of: 360p, 480p, 720p, 1080p, 1440p, portrait-360x640, portrait-480x854, portrait-720x1280, portrait-1080x1920, portrait-1440x2560
    public var qualityTracks: [String]

    public init(autoOn: Bool? = nil, enabled: Bool? = nil, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
    }

    public enum CodingKeys: String, CodingKey {
        case autoOn = "auto_on"
        case enabled
        case qualityTracks = "quality_tracks"
    }
}

extension HLSSettingsRequest: Hashable {
    public static func == (lhs: HLSSettingsRequest, rhs: HLSSettingsRequest) -> Bool {
        lhs.autoOn == rhs.autoOn &&
            lhs.enabled == rhs.enabled &&
            lhs.qualityTracks == rhs.qualityTracks
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(autoOn)
        hasher.combine(enabled)
        hasher.combine(qualityTracks)
    }
}
