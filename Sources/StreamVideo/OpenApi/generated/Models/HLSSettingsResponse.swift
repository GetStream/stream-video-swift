//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct HLSSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
