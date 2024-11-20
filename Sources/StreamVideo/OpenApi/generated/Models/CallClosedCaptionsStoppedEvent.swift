//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallClosedCaptionsStoppedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var type: String = "call.closed_captions_stopped"

    public init(callCid: String, createdAt: Date) {
        self.callCid = callCid
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
    }
    
    public static func == (lhs: CallClosedCaptionsStoppedEvent, rhs: CallClosedCaptionsStoppedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}