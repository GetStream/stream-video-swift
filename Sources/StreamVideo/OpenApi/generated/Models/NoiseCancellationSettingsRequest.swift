//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class NoiseCancellationSettingsRequestMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = NoiseCancellationSettingsRequestMode(rawValue: "auto-on")
    public static let available = NoiseCancellationSettingsRequestMode(rawValue: "available")
    public static let disabled = NoiseCancellationSettingsRequestMode(rawValue: "disabled")
}

public final class NoiseCancellationSettingsRequest: Sendable, Codable, JSONEncodable {
    public let mode: NoiseCancellationSettingsRequestMode

    public init(mode: NoiseCancellationSettingsRequestMode) {
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(NoiseCancellationSettingsRequestMode.self, forKey: .mode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(mode, forKey: .mode)
    }
}

extension NoiseCancellationSettingsRequest: Hashable {
    public static func == (lhs: NoiseCancellationSettingsRequest, rhs: NoiseCancellationSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
