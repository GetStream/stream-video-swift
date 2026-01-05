//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ClosedCaptionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var closedCaption: CallClosedCaption
    public var createdAt: Date
    public var type: String = "call.closed_caption"

    public init(callCid: String, closedCaption: CallClosedCaption, createdAt: Date) {
        self.callCid = callCid
        self.closedCaption = closedCaption
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case closedCaption = "closed_caption"
        case createdAt = "created_at"
        case type
    }
    
    public static func == (lhs: ClosedCaptionEvent, rhs: ClosedCaptionEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.closedCaption == rhs.closedCaption &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(closedCaption)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
