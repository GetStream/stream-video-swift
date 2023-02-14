//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct GeofenceSettings: Codable, JSONEncodable, Hashable {

    internal var names: [String]

    internal init(names: [String]) {
        self.names = names
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(names, forKey: .names)
    }
}
