//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CustomVideoEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var type: String
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON], type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case type
        case user
    }
}
