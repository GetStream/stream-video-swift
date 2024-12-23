//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryAggregateCallStatsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var from: String?
    public var reportTypes: [String]?
    public var to: String?

    public init(from: String? = nil, reportTypes: [String]? = nil, to: String? = nil) {
        self.from = from
        self.reportTypes = reportTypes
        self.to = to
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case from
        case reportTypes = "report_types"
        case to
    }
    
    public static func == (lhs: QueryAggregateCallStatsRequest, rhs: QueryAggregateCallStatsRequest) -> Bool {
        lhs.from == rhs.from &&
            lhs.reportTypes == rhs.reportTypes &&
            lhs.to == rhs.to
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(reportTypes)
        hasher.combine(to)
    }
}
