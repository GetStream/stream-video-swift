//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryCallStatsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var next: String? = nil
    public var prev: String? = nil
    public var reports: [CallStatsReportSummaryResponse]

    public init(duration: String, next: String? = nil, prev: String? = nil, reports: [CallStatsReportSummaryResponse]) {
        self.duration = duration
        self.next = next
        self.prev = prev
        self.reports = reports
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case next
        case prev
        case reports
    }
}
