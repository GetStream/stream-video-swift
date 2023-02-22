//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct SFUResponse: Codable, JSONEncodable, Hashable {

    internal var edgeName: String
    internal var url: String

    internal init(edgeName: String, url: String) {
        self.edgeName = edgeName
        self.url = url
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case edgeName = "edge_name"
        case url
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(edgeName, forKey: .edgeName)
        try container.encode(url, forKey: .url)
    }
}
