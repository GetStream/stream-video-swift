//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct Coordinates: Codable, JSONEncodable, Hashable {

    internal var latitude: Float?
    internal var longitude: Float?

    internal init(latitude: Float? = nil, longitude: Float? = nil) {
        self.latitude = latitude
        self.longitude = longitude
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case latitude
        case longitude
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
    }
}
