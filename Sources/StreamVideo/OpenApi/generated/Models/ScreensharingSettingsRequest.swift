//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct ScreensharingSettingsRequest: Codable, JSONEncodable, Hashable {

    internal var accessRequestEnabled: Bool?
    internal var enabled: Bool?

    internal init(accessRequestEnabled: Bool? = nil, enabled: Bool? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case enabled
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encodeIfPresent(enabled, forKey: .enabled)
    }
}
