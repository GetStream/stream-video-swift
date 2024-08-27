//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct StatsOptions: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var reportingIntervalMs: Int

    public init(reportingIntervalMs: Int) {
        self.reportingIntervalMs = reportingIntervalMs
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reportingIntervalMs = "reporting_interval_ms"
    }
}
