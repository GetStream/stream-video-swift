//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RTMPSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool
    public var quality: String

    public init(enabled: Bool, quality: String) {
        self.enabled = enabled
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case quality
    }
    
    public static func == (lhs: RTMPSettingsResponse, rhs: RTMPSettingsResponse) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(quality)
    }
}
