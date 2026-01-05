//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryCallStatsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var next: String?
    public var prev: String?
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
    
    public static func == (lhs: QueryCallStatsResponse, rhs: QueryCallStatsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.reports == rhs.reports
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(reports)
    }
}
