//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DailyAggregateUserFeedbackReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var date: String
    public var report: UserFeedbackReport

    public init(date: String, report: UserFeedbackReport) {
        self.date = date
        self.report = report
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case date
        case report
    }
    
    public static func == (lhs: DailyAggregateUserFeedbackReportResponse, rhs: DailyAggregateUserFeedbackReportResponse) -> Bool {
        lhs.date == rhs.date &&
            lhs.report == rhs.report
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(report)
    }
}
