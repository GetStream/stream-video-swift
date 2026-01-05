//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallRejectedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var reason: String?
    public var type: String = "call.rejected"
    public var user: UserResponse

    public init(call: CallResponse, callCid: String, createdAt: Date, reason: String? = nil, user: UserResponse) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.reason = reason
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
    
    public static func == (lhs: CallRejectedEvent, rhs: CallRejectedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.reason == rhs.reason &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(reason)
        hasher.combine(type)
        hasher.combine(user)
    }
}
