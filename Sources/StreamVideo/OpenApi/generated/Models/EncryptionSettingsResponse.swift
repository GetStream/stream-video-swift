//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// EncryptionSettings is the payload for end-to-end encryption settings
public final class EncryptionSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum EncryptionSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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

    /// the resolved encryption mode for the call
    public var mode: EncryptionSettingsResponseMode

    public init(mode: EncryptionSettingsResponseMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(EncryptionSettingsResponseMode.self, forKey: .mode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(mode, forKey: .mode)
    }
}

extension EncryptionSettingsResponse: Hashable {
    public static func == (lhs: EncryptionSettingsResponse, rhs: EncryptionSettingsResponse) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
