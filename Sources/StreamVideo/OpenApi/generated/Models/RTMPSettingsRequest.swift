//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RTMPSettingsRequestQuality: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let _1080p = RTMPSettingsRequestQuality(rawValue: "1080p")
    public static let _1440p = RTMPSettingsRequestQuality(rawValue: "1440p")
    public static let _360p = RTMPSettingsRequestQuality(rawValue: "360p")
    public static let _480p = RTMPSettingsRequestQuality(rawValue: "480p")
    public static let _720p = RTMPSettingsRequestQuality(rawValue: "720p")
    public static let portrait1080x1920 = RTMPSettingsRequestQuality(rawValue: "portrait-1080x1920")
    public static let portrait1440x2560 = RTMPSettingsRequestQuality(rawValue: "portrait-1440x2560")
    public static let portrait360x640 = RTMPSettingsRequestQuality(rawValue: "portrait-360x640")
    public static let portrait480x854 = RTMPSettingsRequestQuality(rawValue: "portrait-480x854")
    public static let portrait720x1280 = RTMPSettingsRequestQuality(rawValue: "portrait-720x1280")
}

public final class RTMPSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Whether RTMP broadcasting is enabled
    public var enabled: Bool?
    /// Resolution to set for the RTMP stream. One of: 360p, 480p, 720p, 1080p, 1440p, portrait-360x640, portrait-480x854, portrait-720x1280, portrait-1080x1920, portrait-1440x2560
    public var quality: RTMPSettingsRequestQuality?

    public init(enabled: Bool? = nil, quality: RTMPSettingsRequestQuality? = nil) {
        self.enabled = enabled
        self.quality = quality
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(quality, forKey: .quality)
    }
}

extension RTMPSettingsRequest: Hashable {
    public static func == (lhs: RTMPSettingsRequest, rhs: RTMPSettingsRequest) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(quality)
    }
}
