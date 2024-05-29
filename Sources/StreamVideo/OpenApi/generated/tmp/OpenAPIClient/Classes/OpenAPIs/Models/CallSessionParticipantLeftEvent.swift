//
// CallSessionParticipantLeftEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent when a participant leaves a call session */

public struct CallSessionParticipantLeftEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var participant: CallParticipantResponse
    /** Call session ID */
    public var sessionId: String
    /** The type of event: \"call.session_participant_left\" in this case */
    public var type: String = "call.session_participant_left"

    public init(callCid: String, createdAt: Date, participant: CallParticipantResponse, sessionId: String, type: String = "call.session_participant_left") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.participant = participant
        self.sessionId = sessionId
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case participant
        case sessionId = "session_id"
        case type
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(participant, forKey: .participant)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(type, forKey: .type)
    }
}

