//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallSessionParticipantLeftEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var durationSeconds: Int
    public var participant: CallParticipantResponse
    public var sessionId: String
    public var type: String = "call.session_participant_left"

    public init(callCid: String, createdAt: Date, durationSeconds: Int, participant: CallParticipantResponse, sessionId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.participant = participant
        self.sessionId = sessionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case durationSeconds = "duration_seconds"
        case participant
        case sessionId = "session_id"
        case type
    }
    
    public static func == (lhs: CallSessionParticipantLeftEvent, rhs: CallSessionParticipantLeftEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.durationSeconds == rhs.durationSeconds &&
            lhs.participant == rhs.participant &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(durationSeconds)
        hasher.combine(participant)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
