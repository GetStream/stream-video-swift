//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct RequestPermissionResponse: Codable, JSONEncodable, Hashable {

    internal var duration: String?

    internal init(duration: String? = nil) {
        self.duration = duration
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}
