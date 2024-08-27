//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallReactionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var reaction: ReactionResponse
    public var type: String

    public init(callCid: String, createdAt: Date, reaction: ReactionResponse, type: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.reaction = reaction
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case reaction
        case type
    }
}
