//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class FrameRecordingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum FrameRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
        case autoOn = "auto-on"
        case available = "available"
        case disabled = "disabled"
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

    public init(captureIntervalInSeconds: Int, mode: FrameRecordingSettingsRequestMode, quality: FrameRecordingSettingsRequestQuality? = nil) {
        self.captureIntervalInSeconds = captureIntervalInSeconds
        self.mode = mode
        self.quality = quality
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case captureIntervalInSeconds = "capture_interval_in_seconds"
        case mode
        case quality
    }

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
