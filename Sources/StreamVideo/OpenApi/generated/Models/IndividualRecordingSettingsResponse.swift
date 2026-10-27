//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum IndividualRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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

    public var mode: IndividualRecordingSettingsResponseMode

    public init(mode: IndividualRecordingSettingsResponseMode) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey {
        case mode
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
