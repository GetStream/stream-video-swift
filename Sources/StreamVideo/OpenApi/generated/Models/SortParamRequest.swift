//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct SortParamRequest: Codable, JSONEncodable, Hashable {

    internal var direction: Double?
    internal var field: String?

    internal init(direction: Double? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(field, forKey: .field)
    }
}
