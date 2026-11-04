//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a participant joins a call session
public final class CallSessionParticipantJoinedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    public let participant: CallParticipantResponse
    /// Call session ID
    public let sessionId: String
    /// The type of event: "call.session_participant_joined" in this case
    public let type: String

    public init(
        callCid: String,
        createdAt: Date,
        participant: CallParticipantResponse,
        sessionId: String,
        type: String = "call.session_participant_joined"
    ) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.participant = participant
        self.sessionId = sessionId
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.participant = try container.decode(CallParticipantResponse.self, forKey: .participant)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
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
