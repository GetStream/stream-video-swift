//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct VideoSettings: Codable, JSONEncodable, Hashable {

    internal var accessRequestEnabled: Bool
    internal var enabled: Bool

    internal init(accessRequestEnabled: Bool, enabled: Bool) {
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
        try container.encode(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encode(enabled, forKey: .enabled)
    }
}
