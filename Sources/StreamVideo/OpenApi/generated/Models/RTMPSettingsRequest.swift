//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RTMPSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Quality: String, Sendable, Codable, CaseIterable {
        case _1080p = "1080p"
        case _1440p = "1440p"
        case _360p = "360p"
        case _480p = "480p"
        case _720p = "720p"
        case portrait1080x1920 = "portrait-1080x1920"
        case portrait1440x2560 = "portrait-1440x2560"
        case portrait360x640 = "portrait-360x640"
        case portrait480x854 = "portrait-480x854"
        case portrait720x1280 = "portrait-720x1280"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var enabled: Bool?
    public var quality: Quality?

    public init(enabled: Bool? = nil, quality: Quality? = nil) {
        self.enabled = enabled
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case quality
    }
    
    public static func == (lhs: RTMPSettingsRequest, rhs: RTMPSettingsRequest) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(quality)
    }
}
