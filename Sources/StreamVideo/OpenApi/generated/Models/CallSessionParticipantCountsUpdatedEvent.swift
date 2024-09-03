//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSessionParticipantCountsUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var anonymousParticipantCount: Int
    public var callCid: String
    public var createdAt: Date
    public var participantsCountByRole: [String: Int]
    public var sessionId: String
    public var type: String

    public init(
        anonymousParticipantCount: Int,
        callCid: String,
        createdAt: Date,
        participantsCountByRole: [String: Int],
        sessionId: String,
        type: String
    ) {
        self.anonymousParticipantCount = anonymousParticipantCount
        self.callCid = callCid
        self.createdAt = createdAt
        self.participantsCountByRole = participantsCountByRole
        self.sessionId = sessionId
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case anonymousParticipantCount = "anonymous_participant_count"
        case callCid = "call_cid"
        case createdAt = "created_at"
        case participantsCountByRole = "participants_count_by_role"
        case sessionId = "session_id"
        case type
    }
}
