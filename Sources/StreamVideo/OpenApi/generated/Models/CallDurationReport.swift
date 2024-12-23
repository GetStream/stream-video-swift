//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallDurationReport: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var histogram: [ReportByHistogramBucket]

    public init(histogram: [ReportByHistogramBucket]) {
        self.histogram = histogram
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case histogram
    }
    
    public static func == (lhs: CallDurationReport, rhs: CallDurationReport) -> Bool {
        lhs.histogram == rhs.histogram
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(histogram)
    }
}
