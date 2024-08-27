//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSessionStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var sessionId: String
    public var type: String

    public init(call: CallResponse, callCid: String, createdAt: Date, sessionId: String, type: String) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case sessionId = "session_id"
        case type
    }
}
