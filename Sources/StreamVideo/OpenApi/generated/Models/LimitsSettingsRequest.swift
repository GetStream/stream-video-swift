//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LimitsSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var maxDurationSeconds: Int?
    public var maxParticipants: Int?
    public var maxParticipantsExcludeOwner: Bool?
    public var maxParticipantsExcludeRoles: [String]?

    public init(
        maxDurationSeconds: Int? = nil,
        maxParticipants: Int? = nil,
        maxParticipantsExcludeOwner: Bool? = nil,
        maxParticipantsExcludeRoles: [String]? = nil
    ) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
        self.maxParticipantsExcludeOwner = maxParticipantsExcludeOwner
        self.maxParticipantsExcludeRoles = maxParticipantsExcludeRoles
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(maxDurationSeconds, forKey: .maxDurationSeconds)
        try container.encodeIfPresent(maxParticipants, forKey: .maxParticipants)
        try container.encodeIfPresent(maxParticipantsExcludeOwner, forKey: .maxParticipantsExcludeOwner)
        try container.encodeIfPresent(maxParticipantsExcludeRoles, forKey: .maxParticipantsExcludeRoles)
    }
}

extension LimitsSettingsRequest: Hashable {
    public static func == (lhs: LimitsSettingsRequest, rhs: LimitsSettingsRequest) -> Bool {
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
