//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class MOSStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: MOSStats, rhs: MOSStats) -> Bool {
        lhs.averageScore == rhs.averageScore &&
            lhs.histogramDurationSeconds == rhs.histogramDurationSeconds &&
            lhs.maxScore == rhs.maxScore &&
            lhs.minScore == rhs.minScore
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(averageScore)
        hasher.combine(histogramDurationSeconds)
        hasher.combine(maxScore)
        hasher.combine(minScore)
    }
}
