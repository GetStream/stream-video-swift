//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ThumbnailsSettings: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(enabled, forKey: .enabled)
    }
}

extension ThumbnailsSettings: Hashable {
    public static func == (lhs: ThumbnailsSettings, rhs: ThumbnailsSettings) -> Bool {
        lhs.enabled == rhs.enabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}
