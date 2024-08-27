//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallMissedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var members: [MemberResponse]
    public var notifyUser: Bool
    public var sessionId: String
    public var type: String
    public var user: UserResponse

    public init(
        call: CallResponse,
        callCid: String,
        createdAt: Date,
        members: [MemberResponse],
        notifyUser: Bool,
        sessionId: String,
        type: String,
        user: UserResponse
    ) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.notifyUser = notifyUser
        self.sessionId = sessionId
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case notifyUser = "notify_user"
        case sessionId = "session_id"
        case type
        case user
    }
}
