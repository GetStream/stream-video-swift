//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallMissedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var members: [MemberResponse]
    public var notifyUser: Bool
    public var sessionId: String
    public var type: String = "call.missed"
    public var user: UserResponse

    public init(
        call: CallResponse,
        callCid: String,
        createdAt: Date,
        members: [MemberResponse],
        notifyUser: Bool,
        sessionId: String,
        user: UserResponse
    ) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
        self.notifyUser = notifyUser
        self.sessionId = sessionId
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
    
    public static func == (lhs: CallMissedEvent, rhs: CallMissedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.notifyUser == rhs.notifyUser &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(notifyUser)
        hasher.combine(sessionId)
        hasher.combine(type)
        hasher.combine(user)
    }
}
