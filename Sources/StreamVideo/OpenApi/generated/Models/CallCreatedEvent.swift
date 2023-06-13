//
// CallCreatedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** This event is sent when a call is created. Clients receiving this event should check if the ringing  field is set to true and if so, show the call screen */




public struct CallCreatedEvent: Codable, JSONEncodable, Hashable, WSCallEvent {

    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /** the members added to this call */
    public var members: [MemberResponse]
    /** The type of event: \"call.created\" in this case */
    public var type: String = "call.created"

    public init(call: CallResponse, callCid: String, createdAt: Date, members: [MemberResponse], type: String = "call.created") {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case type
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(members, forKey: .members)
        try container.encode(type, forKey: .type)
    }
}

