//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class QueryCallStatsResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
        self.reports = try container.decode([CallStatsReportSummaryResponse].self, forKey: .reports)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encode(reports, forKey: .reports)
    }
}

extension QueryCallStatsResponse: Hashable {
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
