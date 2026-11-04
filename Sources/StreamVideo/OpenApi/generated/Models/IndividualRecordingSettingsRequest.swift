//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum IndividualRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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

    /// Recording mode. One of: available, disabled, auto-on
    public var mode: IndividualRecordingSettingsRequestMode

    public init(mode: IndividualRecordingSettingsRequestMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(IndividualRecordingSettingsRequestMode.self, forKey: .mode)
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
