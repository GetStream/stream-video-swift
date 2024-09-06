//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Stats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
