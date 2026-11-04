//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsResponseMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = IndividualRecordingSettingsResponseMode(rawValue: "auto-on")
    public static let available = IndividualRecordingSettingsResponseMode(rawValue: "available")
    public static let disabled = IndividualRecordingSettingsResponseMode(rawValue: "disabled")
}

public final class IndividualRecordingSettingsResponse: @unchecked Sendable, Decodable {
    public var mode: IndividualRecordingSettingsResponseMode

    public init(mode: IndividualRecordingSettingsResponseMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(IndividualRecordingSettingsResponseMode.self, forKey: .mode)
    }
}

extension IndividualRecordingSettingsResponse: Hashable {
    public static func == (lhs: IndividualRecordingSettingsResponse, rhs: IndividualRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
