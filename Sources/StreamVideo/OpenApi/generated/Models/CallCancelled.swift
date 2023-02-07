//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallCancelled: Codable, JSONEncodable, Hashable {

    /** Call CID */
    internal var callCid: String?
    internal var createdAt: Date?
    internal var type: String
    internal var user: UserResponse?

    internal init(callCid: String? = nil, createdAt: Date? = nil, type: String, user: UserResponse? = nil) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(callCid, forKey: .callCid)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}
