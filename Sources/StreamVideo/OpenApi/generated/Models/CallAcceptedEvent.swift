//
// CallAcceptedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent when a user accepts a notification to join a call. */

public struct CallAcceptedEvent: Codable, JSONEncodable, Hashable, WSCallEvent {
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /** The type of event: \"call.accepted\" in this case */
    public var type: String = "call.accepted"
    public var user: UserResponse

    public init(call: CallResponse, callCid: String, createdAt: Date, type: String = "call.accepted", user: UserResponse) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

