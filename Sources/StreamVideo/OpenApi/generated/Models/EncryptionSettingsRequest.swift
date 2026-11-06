//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EncryptionSettingsRequestMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = EncryptionSettingsRequestMode(rawValue: "auto-on")
    public static let available = EncryptionSettingsRequestMode(rawValue: "available")
    public static let disabled = EncryptionSettingsRequestMode(rawValue: "disabled")
}

public final class EncryptionSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Encryption mode. One of: available, disabled, auto-on
    public var mode: EncryptionSettingsRequestMode?

    public init(mode: EncryptionSettingsRequestMode? = nil) {
        self.mode = mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(mode, forKey: .mode)
    }
}

extension EncryptionSettingsRequest: Hashable {
    public static func == (lhs: EncryptionSettingsRequest, rhs: EncryptionSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
