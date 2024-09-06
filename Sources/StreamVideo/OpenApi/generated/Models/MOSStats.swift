//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MOSStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var averageScore: Float
    public var histogramDurationSeconds: [Float]
    public var maxScore: Float
    public var minScore: Float

    public init(averageScore: Float, histogramDurationSeconds: [Float], maxScore: Float, minScore: Float) {
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
