//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdatedCallPermissionsEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    public var ownCapabilities: [OwnCapability]
    public var type: String
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, ownCapabilities: [OwnCapability], type: String, user: UserResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.ownCapabilities = ownCapabilities
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case ownCapabilities = "own_capabilities"
        case type
        case user
    }
}
