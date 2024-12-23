//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SDKUsageReport: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var perSdkUsage: [String: PerSDKUsageReport?]

    public init(perSdkUsage: [String: PerSDKUsageReport?]) {
        self.perSdkUsage = perSdkUsage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case perSdkUsage = "per_sdk_usage"
    }
    
    public static func == (lhs: SDKUsageReport, rhs: SDKUsageReport) -> Bool {
        lhs.perSdkUsage == rhs.perSdkUsage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(perSdkUsage)
    }
}
