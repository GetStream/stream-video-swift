//
// CallNotificationEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent to all call members to notify they are getting called */

public struct CallNotificationEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /** Call members */
    public var members: [MemberResponse]
    /** Call session ID */
    public var sessionId: String
    /** The type of event: \"call.notification\" in this case */
    public var type: String = "call.notification"
    public var user: UserResponse

    public init(call: CallResponse, callCid: String, createdAt: Date, members: [MemberResponse], sessionId: String, type: String = "call.notification", user: UserResponse) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.sessionId = sessionId
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case sessionId = "session_id"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(members, forKey: .members)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

