//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallSessionResponse: @unchecked Sendable, Codable, JSONEncodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.acceptedBy = try container.decode([String: Date].self, forKey: .acceptedBy)
        self.anonymousParticipantCount = try container.decode(Int.self, forKey: .anonymousParticipantCount)
        self.endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        self.id = try container.decode(String.self, forKey: .id)
        self.liveEndedAt = try container.decodeIfPresent(Date.self, forKey: .liveEndedAt)
        self.liveStartedAt = try container.decodeIfPresent(Date.self, forKey: .liveStartedAt)
        self.missedBy = try container.decode([String: Date].self, forKey: .missedBy)
        self.participants = try container.decode([CallParticipantResponse].self, forKey: .participants)
        self.participantsCountByRole = try container.decode([String: Int].self, forKey: .participantsCountByRole)
        self.rejectedBy = try container.decode([String: Date].self, forKey: .rejectedBy)
        self.startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        self.timerEndsAt = try container.decodeIfPresent(Date.self, forKey: .timerEndsAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(acceptedBy, forKey: .acceptedBy)
        try container.encode(anonymousParticipantCount, forKey: .anonymousParticipantCount)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(liveEndedAt, forKey: .liveEndedAt)
        try container.encodeIfPresent(liveStartedAt, forKey: .liveStartedAt)
        try container.encode(missedBy, forKey: .missedBy)
        try container.encode(participants, forKey: .participants)
        try container.encode(participantsCountByRole, forKey: .participantsCountByRole)
        try container.encode(rejectedBy, forKey: .rejectedBy)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(timerEndsAt, forKey: .timerEndsAt)
    }
}

extension CallSessionResponse: Hashable {
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
