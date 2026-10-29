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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.autoOn = try container.decodeIfPresent(Bool.self, forKey: .autoOn)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.qualityTracks = try container.decode([String].self, forKey: .qualityTracks)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(autoOn, forKey: .autoOn)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encode(qualityTracks, forKey: .qualityTracks)
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
