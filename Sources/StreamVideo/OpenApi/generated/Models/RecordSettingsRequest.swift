//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RecordSettingsRequestMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = RecordSettingsRequestMode(rawValue: "auto-on")
    public static let available = RecordSettingsRequestMode(rawValue: "available")
    public static let disabled = RecordSettingsRequestMode(rawValue: "disabled")
}

public final class RecordSettingsRequestQuality: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let _1080p = RecordSettingsRequestQuality(rawValue: "1080p")
    public static let _1440p = RecordSettingsRequestQuality(rawValue: "1440p")
    public static let _360p = RecordSettingsRequestQuality(rawValue: "360p")
    public static let _480p = RecordSettingsRequestQuality(rawValue: "480p")
    public static let _720p = RecordSettingsRequestQuality(rawValue: "720p")
    public static let portrait1080x1920 = RecordSettingsRequestQuality(rawValue: "portrait-1080x1920")
    public static let portrait1440x2560 = RecordSettingsRequestQuality(rawValue: "portrait-1440x2560")
    public static let portrait360x640 = RecordSettingsRequestQuality(rawValue: "portrait-360x640")
    public static let portrait480x854 = RecordSettingsRequestQuality(rawValue: "portrait-480x854")
    public static let portrait720x1280 = RecordSettingsRequestQuality(rawValue: "portrait-720x1280")
}

public final class RecordSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Whether to record audio only
    public var audioOnly: Bool?
    /// Recording mode. One of: available, disabled, auto-on
    public var mode: RecordSettingsRequestMode
    /// Recording quality. One of: 360p, 480p, 720p, 1080p, 1440p, portrait-360x640, portrait-480x854, portrait-720x1280, portrait-1080x1920, portrait-1440x2560
    public var quality: RecordSettingsRequestQuality?

    public init(audioOnly: Bool? = nil, mode: RecordSettingsRequestMode, quality: RecordSettingsRequestQuality? = nil) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audioOnly, forKey: .audioOnly)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(quality, forKey: .quality)
    }
}

extension RecordSettingsRequest: Hashable {
    public static func == (lhs: RecordSettingsRequest, rhs: RecordSettingsRequest) -> Bool {
        lhs.audioOnly == rhs.audioOnly &&
            lhs.mode == rhs.mode &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioOnly)
        hasher.combine(mode)
        hasher.combine(quality)
    }
}
