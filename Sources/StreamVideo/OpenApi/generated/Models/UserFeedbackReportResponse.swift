//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserFeedbackReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateUserFeedbackReportResponse]

    public init(daily: [DailyAggregateUserFeedbackReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: UserFeedbackReportResponse, rhs: UserFeedbackReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
