//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct AudioSettings: Codable, JSONEncodable, Hashable {

    internal var accessRequestEnabled: Bool

    internal init(accessRequestEnabled: Bool) {
        self.accessRequestEnabled = accessRequestEnabled
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessRequestEnabled, forKey: .accessRequestEnabled)
    }
}
