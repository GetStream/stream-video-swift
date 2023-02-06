//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallCreated: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse?
    internal var createdAt: Date?
    internal var members: [MemberResponse]?
    internal var ringing: Bool?
    internal var type: String

    internal init(
        call: CallResponse? = nil,
        createdAt: Date? = nil,
        members: [MemberResponse]? = nil,
        ringing: Bool? = nil,
        type: String
    ) {
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
        try container.encodeIfPresent(call, forKey: .call)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(ringing, forKey: .ringing)
        try container.encode(type, forKey: .type)
    }
}
