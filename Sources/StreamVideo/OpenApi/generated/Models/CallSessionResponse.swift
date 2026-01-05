//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallSessionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var acceptedBy: [String: Date]
    public var anonymousParticipantCount: Int
    public var endedAt: Date?
    public var id: String
    public var liveEndedAt: Date?
    public var liveStartedAt: Date?
    public var missedBy: [String: Date]
    public var participants: [CallParticipantResponse]
    public var participantsCountByRole: [String: Int]
    public var rejectedBy: [String: Date]
    public var startedAt: Date?
    public var timerEndsAt: Date?

    public init(
        acceptedBy: [String: Date],
        anonymousParticipantCount: Int,
        endedAt: Date? = nil,
        id: String,
        liveEndedAt: Date? = nil,
        liveStartedAt: Date? = nil,
        missedBy: [String: Date],
        participants: [CallParticipantResponse],
        participantsCountByRole: [String: Int],
        rejectedBy: [String: Date],
        startedAt: Date? = nil,
        timerEndsAt: Date? = nil
    ) {
        self.acceptedBy = acceptedBy
        self.anonymousParticipantCount = anonymousParticipantCount
        self.endedAt = endedAt
        self.id = id
        self.liveEndedAt = liveEndedAt
        self.liveStartedAt = liveStartedAt
        self.missedBy = missedBy
        self.participants = participants
        self.participantsCountByRole = participantsCountByRole
        self.rejectedBy = rejectedBy
        self.startedAt = startedAt
        self.timerEndsAt = timerEndsAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptedBy = "accepted_by"
        case anonymousParticipantCount = "anonymous_participant_count"
        case endedAt = "ended_at"
        case id
        case liveEndedAt = "live_ended_at"
        case liveStartedAt = "live_started_at"
        case missedBy = "missed_by"
        case participants
        case participantsCountByRole = "participants_count_by_role"
        case rejectedBy = "rejected_by"
        case startedAt = "started_at"
        case timerEndsAt = "timer_ends_at"
    }
    
    public static func == (lhs: CallSessionResponse, rhs: CallSessionResponse) -> Bool {
        lhs.acceptedBy == rhs.acceptedBy &&
            lhs.anonymousParticipantCount == rhs.anonymousParticipantCount &&
            lhs.endedAt == rhs.endedAt &&
            lhs.id == rhs.id &&
            lhs.liveEndedAt == rhs.liveEndedAt &&
            lhs.liveStartedAt == rhs.liveStartedAt &&
            lhs.missedBy == rhs.missedBy &&
            lhs.participants == rhs.participants &&
            lhs.participantsCountByRole == rhs.participantsCountByRole &&
            lhs.rejectedBy == rhs.rejectedBy &&
            lhs.startedAt == rhs.startedAt &&
            lhs.timerEndsAt == rhs.timerEndsAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(acceptedBy)
        hasher.combine(anonymousParticipantCount)
        hasher.combine(endedAt)
        hasher.combine(id)
        hasher.combine(liveEndedAt)
        hasher.combine(liveStartedAt)
        hasher.combine(missedBy)
        hasher.combine(participants)
        hasher.combine(participantsCountByRole)
        hasher.combine(rejectedBy)
        hasher.combine(startedAt)
        hasher.combine(timerEndsAt)
    }
}
