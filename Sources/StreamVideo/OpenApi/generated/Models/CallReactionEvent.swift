//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a reaction is sent in a call, clients should use this to show the reaction in the call screen
public final class CallReactionEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    public let reaction: ReactionResponse
    /// The type of event: "call.reaction_new" in this case
    public let type: String

    public init(callCid: String, createdAt: Date, reaction: ReactionResponse, type: String = "call.reaction_new") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.reaction = reaction
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.reaction = try container.decode(ReactionResponse.self, forKey: .reaction)
        self.type = try container.decode(String.self, forKey: .type)
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
