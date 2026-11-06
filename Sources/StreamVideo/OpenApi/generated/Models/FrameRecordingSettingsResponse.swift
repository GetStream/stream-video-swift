//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class FrameRecordingSettingsResponseMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = FrameRecordingSettingsResponseMode(rawValue: "auto-on")
    public static let available = FrameRecordingSettingsResponseMode(rawValue: "available")
    public static let disabled = FrameRecordingSettingsResponseMode(rawValue: "disabled")
}

public final class FrameRecordingSettingsResponse: Sendable, Decodable {
    public let captureIntervalInSeconds: Int
    public let mode: FrameRecordingSettingsResponseMode
    public let quality: String?

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
