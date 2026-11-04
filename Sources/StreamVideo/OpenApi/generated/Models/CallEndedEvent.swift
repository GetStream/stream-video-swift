//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a call is mark as ended for all its participants. Clients receiving this event should leave the call screen
public final class CallEndedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.ended" in this case
    public var type: String = "call.ended"
    /// User response object
    public var user: UserResponse?

    public init(call: CallResponse, callCid: String, createdAt: Date, user: UserResponse? = nil) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserResponse.self, forKey: .user)
    }
}

extension CallEndedEvent: Hashable {
    public static func == (lhs: CallEndedEvent, rhs: CallEndedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
