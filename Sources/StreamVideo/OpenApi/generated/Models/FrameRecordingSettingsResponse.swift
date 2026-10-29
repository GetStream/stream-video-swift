//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class FrameRecordingSettingsResponse: @unchecked Sendable, Decodable {
    
    public enum FrameRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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

    public var captureIntervalInSeconds: Int
    public var mode: FrameRecordingSettingsResponseMode
    public var quality: String?

    public init(captureIntervalInSeconds: Int, mode: FrameRecordingSettingsResponseMode, quality: String? = nil) {
        self.captureIntervalInSeconds = captureIntervalInSeconds
        self.mode = mode
        self.quality = quality
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.captureIntervalInSeconds = try container.decode(Int.self, forKey: .captureIntervalInSeconds)
        self.mode = try container.decode(FrameRecordingSettingsResponseMode.self, forKey: .mode)
        self.quality = try container.decodeIfPresent(String.self, forKey: .quality)
    }
}

extension FrameRecordingSettingsResponse: Hashable {
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
