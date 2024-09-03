//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallRtmpBroadcastFailedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var name: String
    public var type: String

    public init(callCid: String, createdAt: Date, name: String, type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case name
        case type
    }
}
