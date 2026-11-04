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

    public enum CodingKeys: String, CodingKey {
        case enabled
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
