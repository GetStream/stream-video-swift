//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct ScreensharingSettingsRequest: Codable, JSONEncodable, Hashable {

    internal var enabled: Bool?

    internal init(enabled: Bool? = nil) {
        self.enabled = enabled
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
    }
}
