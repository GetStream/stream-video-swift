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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.joinAheadTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .joinAheadTimeSeconds)
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
