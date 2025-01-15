//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SDKUsageReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateSDKUsageReportResponse]

    public init(daily: [DailyAggregateSDKUsageReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: SDKUsageReportResponse, rhs: SDKUsageReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
