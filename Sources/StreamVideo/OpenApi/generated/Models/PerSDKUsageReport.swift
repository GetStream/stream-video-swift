//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PerSDKUsageReport: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var byVersion: [String: Int]
    public var total: Int

    public init(byVersion: [String: Int], total: Int) {
        self.byVersion = byVersion
        self.total = total
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case byVersion = "by_version"
        case total
    }
    
    public static func == (lhs: PerSDKUsageReport, rhs: PerSDKUsageReport) -> Bool {
        lhs.byVersion == rhs.byVersion &&
            lhs.total == rhs.total
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(byVersion)
        hasher.combine(total)
    }
}
