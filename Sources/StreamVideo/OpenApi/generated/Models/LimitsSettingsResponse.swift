//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LimitsSettingsResponse: @unchecked Sendable, Decodable {
    public var maxDurationSeconds: Int?
    public var maxParticipants: Int?

    public init(maxDurationSeconds: Int? = nil, maxParticipants: Int? = nil) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.maxDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .maxDurationSeconds)
        self.maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants)
    }
}

extension LimitsSettingsResponse: Hashable {
    public static func == (lhs: LimitsSettingsResponse, rhs: LimitsSettingsResponse) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
    }
}
