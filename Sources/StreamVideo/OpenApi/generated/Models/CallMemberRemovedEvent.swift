//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallMemberRemovedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var members: [String]
    public var type: String = "call.member_removed"

    public init(call: CallResponse, callCid: String, createdAt: Date, members: [String]) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case createdAt = "created_at"
        case members
        case type
    }
    
    public static func == (lhs: CallMemberRemovedEvent, rhs: CallMemberRemovedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.members == rhs.members &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(members)
        hasher.combine(type)
    }
}
