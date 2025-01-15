//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallDurationReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateCallDurationReportResponse]

    public init(daily: [DailyAggregateCallDurationReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: CallDurationReportResponse, rhs: CallDurationReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
