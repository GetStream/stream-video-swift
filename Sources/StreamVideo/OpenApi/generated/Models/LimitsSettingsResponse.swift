//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class LimitsSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: LimitsSettingsResponse, rhs: LimitsSettingsResponse) -> Bool {
        lhs.maxDurationSeconds == rhs.maxDurationSeconds &&
            lhs.maxParticipants == rhs.maxParticipants
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxDurationSeconds)
        hasher.combine(maxParticipants)
    }
}
