//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RecordSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum RecordSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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
    
    public enum RecordSettingsRequestQuality: String, Sendable, Codable, CaseIterable {
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

    public enum CodingKeys: String, CodingKey {
        case audioOnly = "audio_only"
        case mode
        case quality
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
