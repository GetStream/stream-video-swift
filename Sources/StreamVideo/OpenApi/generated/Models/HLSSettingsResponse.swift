//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// HLSSettings is the payload for HLS settings
public final class HLSSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var autoOn: Bool
    public var enabled: Bool
    public var qualityTracks: [String]

    public init(autoOn: Bool, enabled: Bool, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.autoOn = try container.decode(Bool.self, forKey: .autoOn)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.qualityTracks = try container.decode([String].self, forKey: .qualityTracks)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(autoOn, forKey: .autoOn)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(qualityTracks, forKey: .qualityTracks)
    }
}

extension HLSSettingsResponse: Hashable {
    public static func == (lhs: HLSSettingsResponse, rhs: HLSSettingsResponse) -> Bool {
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
