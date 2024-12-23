//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QualityScoreReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateQualityScoreReportResponse]

    public init(daily: [DailyAggregateQualityScoreReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: QualityScoreReportResponse, rhs: QualityScoreReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
