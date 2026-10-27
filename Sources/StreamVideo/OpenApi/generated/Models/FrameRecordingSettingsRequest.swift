//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class FrameRecordingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum FrameRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
        case autoOn = "auto-on"
        case available
        case disabled
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
    
    public enum FrameRecordingSettingsRequestQuality: String, Sendable, Codable, CaseIterable {
        case _1080p = "1080p"
        case _1440p = "1440p"
        case _360p = "360p"
        case _480p = "480p"
        case _720p = "720p"
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.captureIntervalInSeconds = try container.decode(Int.self, forKey: .captureIntervalInSeconds)
        self.mode = try container.decode(FrameRecordingSettingsRequestMode.self, forKey: .mode)
        self.quality = try container.decodeIfPresent(FrameRecordingSettingsRequestQuality.self, forKey: .quality)
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
