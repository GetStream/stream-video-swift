//
// CallMemberRemovedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** This event is sent when one or more members are removed from a call */




internal struct CallMemberRemovedEvent: Codable, JSONEncodable, Hashable, WSCallEvent {

    internal var call: CallResponse
    internal var callCid: String
    internal var createdAt: Date
    /** the list of member IDs removed from the call */
    internal var members: [String]
    /** The type of event: \"call.member_added\" in this case */
    internal var type: String = "call.member_removed"

    internal init(call: CallResponse, callCid: String, createdAt: Date, members: [String], type: String = "call.member_removed") {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.type = type
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case type
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(members, forKey: .members)
        try container.encode(type, forKey: .type)
    }
}

