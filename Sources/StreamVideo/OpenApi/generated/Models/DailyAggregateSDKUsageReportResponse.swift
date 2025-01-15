//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DailyAggregateSDKUsageReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var date: String
    public var report: SDKUsageReport

    public init(date: String, report: SDKUsageReport) {
        self.date = date
        self.report = report
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case date
        case report
    }
    
    public static func == (lhs: DailyAggregateSDKUsageReportResponse, rhs: DailyAggregateSDKUsageReportResponse) -> Bool {
        lhs.date == rhs.date &&
            lhs.report == rhs.report
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(report)
    }
}
