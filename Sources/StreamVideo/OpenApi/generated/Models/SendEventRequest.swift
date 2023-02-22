//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct SendEventRequest: Codable, JSONEncodable, Hashable {

    internal var custom: [String: AnyCodable]?
    internal var type: String

    internal init(custom: [String: AnyCodable]? = nil, type: String) {
        self.custom = custom
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(type, forKey: .type)
    }
}
