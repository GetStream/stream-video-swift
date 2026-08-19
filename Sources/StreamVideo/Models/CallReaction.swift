//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A reaction a participant sent to the call.
///
/// Reactions arrive with the `call.reaction_new` event and are appended on the
/// sender's ``CallParticipant/reactions``. They are kept until the application
/// removes them, either one at a time with ``Call/consume(_:for:)`` or all at
/// once with ``Call/resetReactions(for:)``, which allows short-lived reactions
/// and sticky ones, such as a raised hand, to coexist.
public struct CallReaction: Identifiable, Sendable, Hashable {

    /// A locally generated identifier, used to remove a specific reaction.
    public let id: String

    /// The reaction type, for example `:raise-hand:`.
    ///
    /// This is the value the sender provided and the value participant sorting
    /// matches on. See ``reactionType(_:)``.
    public let type: String

    /// The emoji shortcode the sender provided, if any.
    public let emojiCode: String?

    /// Any custom data the sender attached to the reaction.
    public let custom: [String: RawJSON]

    /// The user that sent the reaction.
    public let user: User

    /// The date the reaction was received.
    public let createdAt: Date

    /// Creates a reaction.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this reaction.
    ///   - type: The reaction type.
    ///   - emojiCode: The emoji shortcode, if any.
    ///   - custom: Any custom data attached to the reaction.
    ///   - user: The user that sent the reaction.
    ///   - createdAt: The date the reaction was received.
    public init(
        id: String,
        type: String,
        emojiCode: String? = nil,
        custom: [String: RawJSON] = [:],
        user: User,
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.emojiCode = emojiCode
        self.custom = custom
        self.user = user
        self.createdAt = createdAt
    }
}

extension CallReaction {

    /// Creates a reaction from the backend payload.
    ///
    /// - Parameters:
    ///   - response: The reaction payload received with the event.
    ///   - id: A unique identifier for this reaction.
    ///   - createdAt: The date the reaction was received.
    init(
        _ response: ReactionResponse,
        id: String,
        createdAt: Date
    ) {
        self.init(
            id: id,
            type: response.type,
            emojiCode: response.emojiCode,
            custom: response.custom ?? [:],
            user: response.user.toUser,
            createdAt: createdAt
        )
    }
}
