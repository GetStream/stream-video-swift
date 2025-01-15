//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ReportByHistogramBucket: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var category: String
    public var count: Int
    public var lowerBound: Bound?
    public var mean: Float
    public var sum: Float
    public var upperBound: Bound?

    public init(category: String, count: Int, lowerBound: Bound? = nil, mean: Float, sum: Float, upperBound: Bound? = nil) {
        self.category = category
        self.count = count
        self.lowerBound = lowerBound
        self.mean = mean
        self.sum = sum
        self.upperBound = upperBound
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case category
        case count
        case lowerBound = "lower_bound"
        case mean
        case sum
        case upperBound = "upper_bound"
    }
    
    public static func == (lhs: ReportByHistogramBucket, rhs: ReportByHistogramBucket) -> Bool {
        lhs.category == rhs.category &&
            lhs.count == rhs.count &&
            lhs.lowerBound == rhs.lowerBound &&
            lhs.mean == rhs.mean &&
            lhs.sum == rhs.sum &&
            lhs.upperBound == rhs.upperBound
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(category)
        hasher.combine(count)
        hasher.combine(lowerBound)
        hasher.combine(mean)
        hasher.combine(sum)
        hasher.combine(upperBound)
    }
}
