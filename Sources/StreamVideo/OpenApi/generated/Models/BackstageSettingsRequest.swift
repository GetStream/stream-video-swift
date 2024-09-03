//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BackstageSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool? = nil
    public var joinAheadTimeSeconds: Int? = nil

    public init(enabled: Bool? = nil, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
    }
}
