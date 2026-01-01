//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallLiveStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var type: String = "call.live_started"

    public init(call: CallResponse, callCid: String, createdAt: Date) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
    }
    
    public static func == (lhs: CallLiveStartedEvent, rhs: CallLiveStartedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
