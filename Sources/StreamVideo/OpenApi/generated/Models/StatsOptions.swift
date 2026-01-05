//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StatsOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enableRtcStats: Bool
    public var reportingIntervalMs: Int

    public init(enableRtcStats: Bool, reportingIntervalMs: Int) {
        self.enableRtcStats = enableRtcStats
        self.reportingIntervalMs = reportingIntervalMs
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enableRtcStats = "enable_rtc_stats"
        case reportingIntervalMs = "reporting_interval_ms"
    }
    
    public static func == (lhs: StatsOptions, rhs: StatsOptions) -> Bool {
        lhs.enableRtcStats == rhs.enableRtcStats &&
            lhs.reportingIntervalMs == rhs.reportingIntervalMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableRtcStats)
        hasher.combine(reportingIntervalMs)
    }
}
