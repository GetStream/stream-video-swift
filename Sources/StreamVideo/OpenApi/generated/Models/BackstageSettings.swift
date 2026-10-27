//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class BackstageSettings: @unchecked Sendable, Decodable {
    public var enabled: Bool
    public var joinAheadTimeSeconds: Int?

    public init(enabled: Bool, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.joinAheadTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .joinAheadTimeSeconds)
    }
}

extension BackstageSettings: Hashable {
    public static func == (lhs: BackstageSettings, rhs: BackstageSettings) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(joinAheadTimeSeconds)
    }
}
