//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class BackstageSettingsRequest: Sendable, Encodable, JSONEncodable {
    public let enabled: Bool?
    public let joinAheadTimeSeconds: Int?

    public init(enabled: Bool? = nil, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(joinAheadTimeSeconds, forKey: .joinAheadTimeSeconds)
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
