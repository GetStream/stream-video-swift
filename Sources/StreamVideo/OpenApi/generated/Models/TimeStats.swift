//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct TimeStats: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var averageSeconds: Double
    public var maxSeconds: Double

    public init(averageSeconds: Double, maxSeconds: Double) {
        self.averageSeconds = averageSeconds
        self.maxSeconds = maxSeconds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case averageSeconds = "average_seconds"
        case maxSeconds = "max_seconds"
    }
}
