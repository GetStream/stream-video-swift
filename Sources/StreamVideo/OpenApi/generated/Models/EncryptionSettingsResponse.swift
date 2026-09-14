//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EncryptionSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum EncryptionSettingsResponseMode: String, Sendable, Codable, CaseIterable {
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
    /// the resolved encryption mode for the call
    public var mode: EncryptionSettingsResponseMode

    public init(mode: EncryptionSettingsResponseMode) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
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
