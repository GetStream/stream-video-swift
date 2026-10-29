//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the participant counts in a call session are updated
public final class CallSessionParticipantCountsUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var anonymousParticipantCount: Int
    public var callCid: String
    public var createdAt: Date
    public var participantsCountByRole: [String: Int]
    /// Call session ID
    public var sessionId: String
    /// The type of event: "call.session_participant_count_updated" in this case
    public var type: String = "call.session_participant_count_updated"

    public init(
        anonymousParticipantCount: Int,
        callCid: String,
        createdAt: Date,
        participantsCountByRole: [String: Int],
        sessionId: String
    ) {
        self.anonymousParticipantCount = anonymousParticipantCount
        self.callCid = callCid
        self.createdAt = createdAt
        self.participantsCountByRole = participantsCountByRole
        self.sessionId = sessionId
    }

    public enum CodingKeys: String, CodingKey {
        case anonymousParticipantCount = "anonymous_participant_count"
        case callCid = "call_cid"
        case createdAt = "created_at"
        case participantsCountByRole = "participants_count_by_role"
        case sessionId = "session_id"
        case type
    }
}

extension CallSessionParticipantCountsUpdatedEvent: Hashable {
    public static func == (lhs: CallSessionParticipantCountsUpdatedEvent, rhs: CallSessionParticipantCountsUpdatedEvent) -> Bool {
        lhs.anonymousParticipantCount == rhs.anonymousParticipantCount &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.participantsCountByRole == rhs.participantsCountByRole &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(anonymousParticipantCount)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(participantsCountByRole)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
