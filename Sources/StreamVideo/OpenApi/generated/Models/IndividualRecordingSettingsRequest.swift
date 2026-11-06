//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsRequestMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = IndividualRecordingSettingsRequestMode(rawValue: "auto-on")
    public static let available = IndividualRecordingSettingsRequestMode(rawValue: "available")
    public static let disabled = IndividualRecordingSettingsRequestMode(rawValue: "disabled")
}

public final class IndividualRecordingSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Recording mode. One of: available, disabled, auto-on
    public var mode: IndividualRecordingSettingsRequestMode

    public init(mode: IndividualRecordingSettingsRequestMode) {
        self.mode = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(mode, forKey: .mode)
    }
}

extension IndividualRecordingSettingsRequest: Hashable {
    public static func == (lhs: IndividualRecordingSettingsRequest, rhs: IndividualRecordingSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
