//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DailyAggregateQualityScoreReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var date: String
    public var report: QualityScoreReport

    public init(date: String, report: QualityScoreReport) {
        self.date = date
        self.report = report
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case date
        case report
    }
    
    public static func == (lhs: DailyAggregateQualityScoreReportResponse, rhs: DailyAggregateQualityScoreReportResponse) -> Bool {
        lhs.date == rhs.date &&
            lhs.report == rhs.report
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(report)
    }
}
