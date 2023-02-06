//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct GetCallEdgeServerResponse: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse
    internal var credentials: Credentials
    /** Duration of the request in human-readable format */
    internal var duration: String?
    internal var members: [MemberResponse]?
    internal var membership: MemberResponse?

    internal init(
        call: CallResponse,
        credentials: Credentials,
        duration: String? = nil,
        members: [MemberResponse]? = nil,
        membership: MemberResponse? = nil
    ) {
        self.call = call
        self.credentials = credentials
        self.duration = duration
        self.members = members
        self.membership = membership
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case credentials
        case duration
        case members
        case membership
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(credentials, forKey: .credentials)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(membership, forKey: .membership)
    }
}
