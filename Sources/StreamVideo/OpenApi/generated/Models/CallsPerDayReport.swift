//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallsPerDayReport: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var count: Int

    public init(count: Int) {
        self.count = count
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case count
    }
    
    public static func == (lhs: CallsPerDayReport, rhs: CallsPerDayReport) -> Bool {
        lhs.count == rhs.count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
    }
}
