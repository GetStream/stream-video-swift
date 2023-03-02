//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct JoinCallResponse: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse
    internal var created: Bool?
    internal var duration: String?
    internal var edges: [DatacenterResponse]?
    internal var members: [MemberResponse]?
    internal var membership: MemberResponse?

    internal init(
        call: CallResponse,
        created: Bool? = nil,
        duration: String? = nil,
        edges: [DatacenterResponse]? = nil,
        members: [MemberResponse]? = nil,
        membership: MemberResponse? = nil
    ) {
        self.call = call
        self.created = created
        self.duration = duration
        self.edges = edges
        self.members = members
        self.membership = membership
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case created
        case duration
        case edges
        case members
        case membership
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encodeIfPresent(created, forKey: .created)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(edges, forKey: .edges)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(membership, forKey: .membership)
    }
}
