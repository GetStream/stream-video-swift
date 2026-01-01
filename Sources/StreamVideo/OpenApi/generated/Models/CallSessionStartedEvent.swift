//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallSessionStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var sessionId: String
    public var type: String = "call.session_started"

    public init(call: CallResponse, callCid: String, createdAt: Date, sessionId: String) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case sessionId = "session_id"
        case type
    }
    
    public static func == (lhs: CallSessionStartedEvent, rhs: CallSessionStartedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
