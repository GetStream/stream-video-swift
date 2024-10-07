//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StatsOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var reportingIntervalMs: Int

    public init(reportingIntervalMs: Int) {
        self.reportingIntervalMs = reportingIntervalMs
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reportingIntervalMs = "reporting_interval_ms"
    }
    
    public static func == (lhs: StatsOptions, rhs: StatsOptions) -> Bool {
        lhs.reportingIntervalMs == rhs.reportingIntervalMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(reportingIntervalMs)
    }
}
