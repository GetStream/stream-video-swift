//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RawRecordingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum RawRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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
    public var mode: RawRecordingSettingsRequestMode

    public init(mode: RawRecordingSettingsRequestMode) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }

    public static func == (lhs: RawRecordingSettingsRequest, rhs: RawRecordingSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
