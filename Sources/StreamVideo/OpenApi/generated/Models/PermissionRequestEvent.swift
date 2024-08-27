//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PermissionRequestEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var permissions: [String]
    public var type: String
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, permissions: [String], type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.permissions = permissions
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case permissions
        case type
        case user
    }
}
