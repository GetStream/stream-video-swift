//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSessionParticipantLeftEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var participant: CallParticipantResponse
    public var sessionId: String
    public var type: String

    public init(callCid: String, createdAt: Date, participant: CallParticipantResponse, sessionId: String, type: String) {
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
}
