//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserFeedbackReport: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var countByRating: [String: Int]
    public var unreportedCount: Int

    public init(countByRating: [String: Int], unreportedCount: Int) {
        self.countByRating = countByRating
        self.unreportedCount = unreportedCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case countByRating = "count_by_rating"
        case unreportedCount = "unreported_count"
    }
    
    public static func == (lhs: UserFeedbackReport, rhs: UserFeedbackReport) -> Bool {
        lhs.countByRating == rhs.countByRating &&
            lhs.unreportedCount == rhs.unreportedCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(countByRating)
        hasher.combine(unreportedCount)
    }
}
