//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RawRecordingSettingsRequestMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = RawRecordingSettingsRequestMode(rawValue: "auto-on")
    public static let available = RawRecordingSettingsRequestMode(rawValue: "available")
    public static let disabled = RawRecordingSettingsRequestMode(rawValue: "disabled")
}

public final class RawRecordingSettingsRequest: Sendable, Encodable, JSONEncodable {
    /// Recording mode. One of: available, disabled, auto-on
    public let mode: RawRecordingSettingsRequestMode

    public init(mode: RawRecordingSettingsRequestMode) {
        self.mode = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(mode, forKey: .mode)
    }
}

extension RawRecordingSettingsRequest: Hashable {
    public static func == (lhs: RawRecordingSettingsRequest, rhs: RawRecordingSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
