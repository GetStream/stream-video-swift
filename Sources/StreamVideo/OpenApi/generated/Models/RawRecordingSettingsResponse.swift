//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RawRecordingSettingsResponseMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = RawRecordingSettingsResponseMode(rawValue: "auto-on")
    public static let available = RawRecordingSettingsResponseMode(rawValue: "available")
    public static let disabled = RawRecordingSettingsResponseMode(rawValue: "disabled")
}

public final class RawRecordingSettingsResponse: @unchecked Sendable, Decodable {
    public var mode: RawRecordingSettingsResponseMode

    public init(mode: RawRecordingSettingsResponseMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(RawRecordingSettingsResponseMode.self, forKey: .mode)
    }
}

extension RawRecordingSettingsResponse: Hashable {
    public static func == (lhs: RawRecordingSettingsResponse, rhs: RawRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
