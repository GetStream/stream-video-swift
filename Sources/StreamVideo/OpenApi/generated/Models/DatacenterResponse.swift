//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct DatacenterResponse: Codable, JSONEncodable, Hashable {

    internal var coordinates: Coordinates
    internal var latencyUrl: String
    internal var name: String

    internal init(coordinates: Coordinates, latencyUrl: String, name: String) {
        self.coordinates = coordinates
        self.latencyUrl = latencyUrl
        self.name = name
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case coordinates
        case latencyUrl = "latency_url"
        case name
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(latencyUrl, forKey: .latencyUrl)
        try container.encode(name, forKey: .name)
    }
}
