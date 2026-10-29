//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a reaction is sent in a call, clients should use this to show the reaction in the call screen
public final class CallReactionEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var reaction: ReactionResponse
    /// The type of event: "call.reaction_new" in this case
    public var type: String = "call.reaction_new"

    public init(callCid: String, createdAt: Date, reaction: ReactionResponse) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.reaction = reaction
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case reaction
        case type
    }
}

extension CallReactionEvent: Hashable {
    public static func == (lhs: CallReactionEvent, rhs: CallReactionEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.reaction == rhs.reaction &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(reaction)
        hasher.combine(type)
    }
}
