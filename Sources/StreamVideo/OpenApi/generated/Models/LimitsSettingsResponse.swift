//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LimitsSettingsResponse: Sendable, Decodable {
    public let maxDurationSeconds: Int?
    public let maxParticipants: Int?
    public let maxParticipantsExcludeOwner: Bool?
    public let maxParticipantsExcludeRoles: [String]

    public init(
        maxDurationSeconds: Int? = nil,
        maxParticipants: Int? = nil,
        maxParticipantsExcludeOwner: Bool? = nil,
        maxParticipantsExcludeRoles: [String]
    ) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
        self.maxParticipantsExcludeOwner = maxParticipantsExcludeOwner
        self.maxParticipantsExcludeRoles = maxParticipantsExcludeRoles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.maxDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .maxDurationSeconds)
        self.maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants)
        self.maxParticipantsExcludeOwner = try container.decodeIfPresent(Bool.self, forKey: .maxParticipantsExcludeOwner)
        self.maxParticipantsExcludeRoles = try container.decode([String].self, forKey: .maxParticipantsExcludeRoles)
    }
}

extension LimitsSettingsResponse: Hashable {
    public static func == (lhs: LimitsSettingsResponse, rhs: LimitsSettingsResponse) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants &&
            lhs.maxParticipantsExcludeOwner == rhs.maxParticipantsExcludeOwner &&
            lhs.maxParticipantsExcludeRoles == rhs.maxParticipantsExcludeRoles
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
        hasher.combine(maxParticipantsExcludeOwner)
        hasher.combine(maxParticipantsExcludeRoles)
    }
}
