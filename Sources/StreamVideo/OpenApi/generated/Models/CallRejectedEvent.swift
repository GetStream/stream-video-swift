//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallRejectedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var reason: String? = nil
    public var type: String
    public var user: UserResponse

    public init(call: CallResponse, callCid: String, createdAt: Date, reason: String? = nil, type: String, user: UserResponse) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.reason = reason
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case reason
        case type
        case user
    }
}
