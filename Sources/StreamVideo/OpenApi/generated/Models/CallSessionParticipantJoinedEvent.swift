//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a participant joins a call session
public final class CallSessionParticipantJoinedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var participant: CallParticipantResponse
    /// Call session ID
    public var sessionId: String
    /// The type of event: "call.session_participant_joined" in this case
    public var type: String = "call.session_participant_joined"

    public init(callCid: String, createdAt: Date, participant: CallParticipantResponse, sessionId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.participant = participant
        self.sessionId = sessionId
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case participant
        case sessionId = "session_id"
        case type
    }
}

extension CallSessionParticipantJoinedEvent: Hashable {
    public static func == (lhs: CallSessionParticipantJoinedEvent, rhs: CallSessionParticipantJoinedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.participant == rhs.participant &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(participant)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
