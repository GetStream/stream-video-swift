//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EncryptionSettingsResponseMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = EncryptionSettingsResponseMode(rawValue: "auto-on")
    public static let available = EncryptionSettingsResponseMode(rawValue: "available")
    public static let disabled = EncryptionSettingsResponseMode(rawValue: "disabled")
}

/// EncryptionSettings is the payload for end-to-end encryption settings
public final class EncryptionSettingsResponse: Sendable, Decodable {
    /// the resolved encryption mode for the call
    public let mode: EncryptionSettingsResponseMode

    public init(mode: EncryptionSettingsResponseMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(EncryptionSettingsResponseMode.self, forKey: .mode)
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
