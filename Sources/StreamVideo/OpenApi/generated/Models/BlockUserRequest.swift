//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct BlockUserRequest: Codable, JSONEncodable, Hashable {

    /** the user to block */
    internal var userId: String

    internal init(userId: String) {
        self.userId = userId
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
    }
}
