//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct HLSSettings: Codable, JSONEncodable, Hashable {

    internal var autoOn: Bool
    internal var enabled: Bool
    internal var qualityTracks: [String]

    internal init(autoOn: Bool, enabled: Bool, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        case enabled
        case qualityTracks = "quality_tracks"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoOn, forKey: .autoOn)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(qualityTracks, forKey: .qualityTracks)
    }
}
