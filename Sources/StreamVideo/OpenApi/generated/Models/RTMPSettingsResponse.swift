//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// RTMPSettingsResponse is the payload for RTMP settings
public final class RTMPSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool
    public var quality: String

    public init(enabled: Bool, quality: String) {
        self.enabled = enabled
        self.quality = quality
    }

    public enum CodingKeys: String, CodingKey {
        case enabled
        case quality
    }
}

extension RTMPSettingsResponse: Hashable {
    public static func == (lhs: RTMPSettingsResponse, rhs: RTMPSettingsResponse) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(quality)
    }
}
