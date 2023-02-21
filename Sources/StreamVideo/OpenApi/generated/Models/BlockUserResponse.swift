//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct BlockUserResponse: Codable, JSONEncodable, Hashable {

    /** Duration of the request in human-readable format */
    internal var duration: String

    internal init(duration: String) {
        self.duration = duration
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
    }
}
