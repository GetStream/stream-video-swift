//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class FrameRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum FrameRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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
    public var captureIntervalInSeconds: Int
    public var mode: FrameRecordingSettingsResponseMode
    public var quality: String?

    public init(captureIntervalInSeconds: Int, mode: FrameRecordingSettingsResponseMode, quality: String? = nil) {
        self.captureIntervalInSeconds = captureIntervalInSeconds
        self.mode = mode
        self.quality = quality
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case captureIntervalInSeconds = "capture_interval_in_seconds"
        case mode
        case quality
    }

    public static func == (lhs: FrameRecordingSettingsResponse, rhs: FrameRecordingSettingsResponse) -> Bool {
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
