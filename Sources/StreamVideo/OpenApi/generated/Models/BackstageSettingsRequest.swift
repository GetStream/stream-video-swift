//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class BackstageSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool?
    public var joinAheadTimeSeconds: Int?

    public init(enabled: Bool? = nil, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }

    public enum CodingKeys: String, CodingKey {
        case enabled
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
    }
}

extension BackstageSettingsRequest: Hashable {
    public static func == (lhs: BackstageSettingsRequest, rhs: BackstageSettingsRequest) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(joinAheadTimeSeconds)
    }
}
