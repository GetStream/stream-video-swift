//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// Maps the emoji shortcodes the Stream SDKs send onto the emoji to present.
///
/// Applications sending custom reactions can provide their own mapping to
/// ``VideoCallParticipantReactionsModifier``.
public let defaultEmojiReactionMapping: [String: String] = [
    ":like:": "👍",
    ":raise-hand:": "✋",
    ":fireworks:": "🎉",
    ":tada:": "🎉",
    ":dislike:": "👎",
    ":heart:": "❤️",
    ":hello:": "👋",
    ":smile:": "😀"
]

/// A view modifier that presents the reactions a participant sent.
///
/// The most recent reaction is shown over the participant's view. Reactions are
/// removed from ``CallParticipant/reactions`` once presented, so the list does
/// not grow for the duration of the call. A raised hand is left in place, as it
/// stays meaningful until the participant lowers it, and participant sorting
/// relies on it.
@MainActor
public struct VideoCallParticipantReactionsModifier: ViewModifier {

    @Injected(\.appearance) private var appearance

    public var participant: CallParticipant
    public var call: Call?
    public var duration: TimeInterval
    public var emojiMapping: [String: String]

    /// Creates the modifier.
    ///
    /// - Parameters:
    ///   - participant: The participant whose reactions are presented.
    ///   - call: The call the participant belongs to.
    ///   - duration: How long a reaction stays visible. Defaults to 5.5
    ///     seconds.
    ///   - emojiMapping: Maps emoji shortcodes onto the emoji to present.
    public init(
        participant: CallParticipant,
        call: Call?,
        duration: TimeInterval = 5.5,
        emojiMapping: [String: String] = defaultEmojiReactionMapping
    ) {
        self.participant = participant
        self.call = call
        self.duration = duration
        self.emojiMapping = emojiMapping
    }

    public func body(content: Content) -> some View {
        content.overlay(reactionView)
    }

    @ViewBuilder
    private var reactionView: some View {
        if let reaction = participant.reactions.last {
            content(for: reaction)
                /// The identity is tied to the reaction, so a newly received one
                /// is presented and scheduled for removal in its own turn.
                .id(reaction.id)
                .allowsHitTesting(false)
                .onAppear { scheduleRemoval(of: reaction) }
        }
    }

    /// The badge presented for the given reaction.
    ///
    /// Reactions the mapping doesn't cover present nothing, while still taking
    /// part in the removal schedule so they don't hide the ones behind them.
    @ViewBuilder
    private func content(for reaction: CallReaction) -> some View {
        if let emoji = reaction.emoji(from: emojiMapping) {
            Text(emoji)
                .font(appearance.fonts.title)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.6)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
                .accessibility(label: Text(reaction.type))
        } else {
            Color.clear
        }
    }

    /// Removes the reaction once it has been presented for ``duration``.
    ///
    /// Reactions that remain meaningful, such as a raised hand, are skipped.
    private func scheduleRemoval(of reaction: CallReaction) {
        guard let call, !reaction.isSticky else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            call.consume(reaction, for: participant.sessionId)
        }
    }
}

extension CallReaction {

    /// Returns the emoji to present for this reaction, if it maps to one.
    ///
    /// The emoji shortcode is preferred, since that is what the other Stream
    /// SDKs map on, and the reaction type is used as a fallback for senders that
    /// provide only a type.
    ///
    /// - Parameter mapping: Maps emoji shortcodes onto the emoji to present.
    /// - Returns: The emoji to present, or `nil` when the reaction is unknown.
    func emoji(from mapping: [String: String]) -> String? {
        if let emojiCode, let emoji = mapping[emojiCode] {
            return emoji
        }
        return mapping[type]
    }

    /// Whether the reaction stays visible until the sender removes it.
    ///
    /// A raised hand remains relevant for as long as it is up, and participant
    /// sorting relies on it, so it isn't dismissed on a timer.
    var isSticky: Bool {
        raisedHandReactionTypes.contains(type)
    }
}
