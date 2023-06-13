//
// CallSessionParticipantLeftEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** This event is sent when a participant leaves a call session */




public struct CallSessionParticipantLeftEvent: Codable, JSONEncodable, Hashable, WSCallEvent {

    public var callCid: String
    public var createdAt: Date
    /** Call session ID */
    public var sessionId: String
    /** The type of event: \"call.session_participant_left\" in this case */
    public var type: String = "call.session_participant_left"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, sessionId: String, type: String = "call.session_participant_left", user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case sessionId = "session_id"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(type, forKey: .type)
        try container.encode(user, forKey: .user)
    }
}

