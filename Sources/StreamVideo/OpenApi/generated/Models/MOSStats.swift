//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MOSStats: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var averageScore: Double
    public var histogramDurationSeconds: [Double]
    public var maxScore: Double
    public var minScore: Double

    public init(averageScore: Double, histogramDurationSeconds: [Double], maxScore: Double, minScore: Double) {
        self.averageScore = averageScore
        self.histogramDurationSeconds = histogramDurationSeconds
        self.maxScore = maxScore
        self.minScore = minScore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case averageScore = "average_score"
        case histogramDurationSeconds = "histogram_duration_seconds"
        case maxScore = "max_score"
        case minScore = "min_score"
    }
}
