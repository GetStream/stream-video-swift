//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct LimitsSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
