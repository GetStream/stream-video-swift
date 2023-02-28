//
// JoinCallResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct JoinCallResponse: Codable, JSONEncodable, Hashable {

    internal var blockedUsers: [UserResponse]
    internal var call: CallResponse
    internal var created: Bool
    internal var duration: String
    internal var edges: [DatacenterResponse]
    internal var members: [MemberResponse]
    internal var membership: MemberResponse?

    internal init(blockedUsers: [UserResponse], call: CallResponse, created: Bool, duration: String, edges: [DatacenterResponse], members: [MemberResponse], membership: MemberResponse? = nil) {
        self.blockedUsers = blockedUsers
        self.call = call
        self.created = created
        self.duration = duration
        self.edges = edges
        self.members = members
        self.membership = membership
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUsers = "blocked_users"
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
        try container.encode(blockedUsers, forKey: .blockedUsers)
        try container.encode(call, forKey: .call)
        try container.encode(created, forKey: .created)
        try container.encode(duration, forKey: .duration)
        try container.encode(edges, forKey: .edges)
        try container.encode(members, forKey: .members)
        try container.encodeIfPresent(membership, forKey: .membership)
    }
}

