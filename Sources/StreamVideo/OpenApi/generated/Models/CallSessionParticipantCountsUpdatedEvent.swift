//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the participant counts in a call session are updated
public final class CallSessionParticipantCountsUpdatedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let anonymousParticipantCount: Int
    public let callCid: String
    public let createdAt: Date
    public let participantsCountByRole: [String: Int]
    /// Call session ID
    public let sessionId: String
    /// The type of event: "call.session_participant_count_updated" in this case
    public let type: String

    public init(
        anonymousParticipantCount: Int,
        callCid: String,
        createdAt: Date,
        participantsCountByRole: [String: Int],
        sessionId: String,
        type: String = "call.session_participant_count_updated"
    ) {
        self.anonymousParticipantCount = anonymousParticipantCount
        self.callCid = callCid
        self.createdAt = createdAt
        self.participantsCountByRole = participantsCountByRole
        self.sessionId = sessionId
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.anonymousParticipantCount = try container.decode(Int.self, forKey: .anonymousParticipantCount)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.participantsCountByRole = try container.decode([String: Int].self, forKey: .participantsCountByRole)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
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
