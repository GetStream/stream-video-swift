//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IndividualRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum IndividualRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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
    public var mode: IndividualRecordingSettingsResponseMode

    public init(mode: IndividualRecordingSettingsResponseMode) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }

    public static func == (lhs: IndividualRecordingSettingsResponse, rhs: IndividualRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
