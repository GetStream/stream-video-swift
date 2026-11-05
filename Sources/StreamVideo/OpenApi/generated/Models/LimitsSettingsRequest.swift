//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LimitsSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var maxDurationSeconds: Int?
    public var maxParticipants: Int?

    public init(maxDurationSeconds: Int? = nil, maxParticipants: Int? = nil) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(maxDurationSeconds, forKey: .maxDurationSeconds)
        try container.encodeIfPresent(maxParticipants, forKey: .maxParticipants)
    }
}

extension LimitsSettingsRequest: Hashable {
    public static func == (lhs: LimitsSettingsRequest, rhs: LimitsSettingsRequest) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
    }
}
