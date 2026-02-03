//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IndividualRecordingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum IndividualRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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
    public var mode: IndividualRecordingSettingsRequestMode

    public init(mode: IndividualRecordingSettingsRequestMode) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }

    public static func == (lhs: IndividualRecordingSettingsRequest, rhs: IndividualRecordingSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
