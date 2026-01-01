//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallRtmpBroadcastStoppedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var name: String
    public var type: String = "call.rtmp_broadcast_stopped"

    public init(callCid: String, createdAt: Date, name: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case name
        case type
    }
    
    public static func == (lhs: CallRtmpBroadcastStoppedEvent, rhs: CallRtmpBroadcastStoppedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.name == rhs.name &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(name)
        hasher.combine(type)
    }
}
