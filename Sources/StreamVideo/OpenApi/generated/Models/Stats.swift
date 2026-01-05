//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Stats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var averageSeconds: Float
    public var maxSeconds: Float

    public init(averageSeconds: Float, maxSeconds: Float) {
        self.averageSeconds = averageSeconds
        self.maxSeconds = maxSeconds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case averageSeconds = "average_seconds"
        case maxSeconds = "max_seconds"
    }
    
    public static func == (lhs: Stats, rhs: Stats) -> Bool {
        lhs.averageSeconds == rhs.averageSeconds &&
            lhs.maxSeconds == rhs.maxSeconds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(averageSeconds)
        hasher.combine(maxSeconds)
    }
}
