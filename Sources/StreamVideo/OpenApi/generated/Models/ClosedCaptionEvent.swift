//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ClosedCaptionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var closedCaption: CallClosedCaption
    public var createdAt: Date
    public var type: String

    public init(callCid: String, closedCaption: CallClosedCaption, createdAt: Date, type: String) {
        self.callCid = callCid
        self.closedCaption = closedCaption
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case closedCaption = "closed_caption"
        case createdAt = "created_at"
        case type
    }
}
