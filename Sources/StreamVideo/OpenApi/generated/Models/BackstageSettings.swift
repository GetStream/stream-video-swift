//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class BackstageSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool
    public var joinAheadTimeSeconds: Int?

    public init(enabled: Bool, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
    }
    
    public static func == (lhs: BackstageSettings, rhs: BackstageSettings) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(joinAheadTimeSeconds)
    }
}
