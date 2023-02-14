//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallCreated: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse
    internal var createdAt: Date
    internal var members: [MemberResponse]
    internal var ringing: Bool
    internal var type: String

    internal init(call: CallResponse, createdAt: Date, members: [MemberResponse], ringing: Bool, type: String) {
        self.call = call
        self.createdAt = createdAt
        self.members = members
        self.ringing = ringing
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case createdAt = "created_at"
        case members
        case ringing
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(members, forKey: .members)
        try container.encode(ringing, forKey: .ringing)
        try container.encode(type, forKey: .type)
    }
}
