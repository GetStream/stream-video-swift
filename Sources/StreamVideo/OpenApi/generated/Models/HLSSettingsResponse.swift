//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class HLSSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var autoOn: Bool
    public var enabled: Bool
    public var qualityTracks: [String]

    public init(autoOn: Bool, enabled: Bool, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        case enabled
        case qualityTracks = "quality_tracks"
    }
    
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
