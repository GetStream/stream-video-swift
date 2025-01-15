//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallsPerDayReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateCallsPerDayReportResponse]

    public init(daily: [DailyAggregateCallsPerDayReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: CallsPerDayReportResponse, rhs: CallsPerDayReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
