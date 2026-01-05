//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class LimitsSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var maxDurationSeconds: Int?
    public var maxParticipants: Int?

    public init(maxDurationSeconds: Int? = nil, maxParticipants: Int? = nil) {
        self.maxDurationSeconds = maxDurationSeconds
        self.maxParticipants = maxParticipants
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case maxDurationSeconds = "max_duration_seconds"
        case maxParticipants = "max_participants"
    }
    
    public static func == (lhs: LimitsSettingsRequest, rhs: LimitsSettingsRequest) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
    }
}
