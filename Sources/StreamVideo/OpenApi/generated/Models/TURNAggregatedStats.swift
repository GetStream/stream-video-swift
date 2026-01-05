//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class TURNAggregatedStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var tcp: Count?
    public var total: Count?

    public init(tcp: Count? = nil, total: Count? = nil) {
        self.tcp = tcp
        self.total = total
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case tcp
        case total
    }
    
    public static func == (lhs: TURNAggregatedStats, rhs: TURNAggregatedStats) -> Bool {
        lhs.tcp == rhs.tcp &&
            lhs.total == rhs.total
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(tcp)
        hasher.combine(total)
    }
}
