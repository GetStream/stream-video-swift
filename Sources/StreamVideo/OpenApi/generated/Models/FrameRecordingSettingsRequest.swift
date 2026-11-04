//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class FrameRecordingSettingsRequestMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = FrameRecordingSettingsRequestMode(rawValue: "auto-on")
    public static let available = FrameRecordingSettingsRequestMode(rawValue: "available")
    public static let disabled = FrameRecordingSettingsRequestMode(rawValue: "disabled")
}

public final class FrameRecordingSettingsRequestQuality: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let _1080p = FrameRecordingSettingsRequestQuality(rawValue: "1080p")
    public static let _1440p = FrameRecordingSettingsRequestQuality(rawValue: "1440p")
    public static let _360p = FrameRecordingSettingsRequestQuality(rawValue: "360p")
    public static let _480p = FrameRecordingSettingsRequestQuality(rawValue: "480p")
    public static let _720p = FrameRecordingSettingsRequestQuality(rawValue: "720p")
}

public final class FrameRecordingSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var captureIntervalInSeconds: Int
    public var mode: FrameRecordingSettingsRequestMode
    public var quality: FrameRecordingSettingsRequestQuality?

    public init(
        captureIntervalInSeconds: Int,
        mode: FrameRecordingSettingsRequestMode,
        quality: FrameRecordingSettingsRequestQuality? = nil
    ) {
        self.captureIntervalInSeconds = captureIntervalInSeconds
        self.mode = mode
        self.quality = quality
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(captureIntervalInSeconds, forKey: .captureIntervalInSeconds)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(quality, forKey: .quality)
    }
}

extension FrameRecordingSettingsRequest: Hashable {
    public static func == (lhs: FrameRecordingSettingsRequest, rhs: FrameRecordingSettingsRequest) -> Bool {
        lhs.captureIntervalInSeconds == rhs.captureIntervalInSeconds &&
            lhs.mode == rhs.mode &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(captureIntervalInSeconds)
        hasher.combine(mode)
        hasher.combine(quality)
    }
}
