//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class VideoCallParticipantReactionsModifier_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - emoji(from:)

    func test_emoji_knownEmojiCode_returnsMappedEmoji() {
        let subject = CallReaction.dummy(type: "raised-hand", emojiCode: ":raise-hand:")

        XCTAssertEqual(subject.emoji(from: defaultEmojiReactionMapping), "✋")
    }

    func test_emoji_noEmojiCodeButKnownType_returnsMappedEmoji() {
        let subject = CallReaction.dummy(type: ":like:", emojiCode: nil)

        XCTAssertEqual(subject.emoji(from: defaultEmojiReactionMapping), "👍")
    }

    func test_emoji_unknownEmojiCodeButKnownType_fallsBackOnType() {
        let subject = CallReaction.dummy(type: ":like:", emojiCode: ":not-a-reaction:")

        XCTAssertEqual(subject.emoji(from: defaultEmojiReactionMapping), "👍")
    }

    func test_emoji_unknownReaction_returnsNil() {
        let subject = CallReaction.dummy(type: ":unknown:", emojiCode: ":unknown:")

        XCTAssertNil(subject.emoji(from: defaultEmojiReactionMapping))
    }

    func test_emoji_customMapping_returnsCustomEmoji() {
        let subject = CallReaction.dummy(type: ":party:", emojiCode: ":party:")

        XCTAssertEqual(subject.emoji(from: [":party:": "🥳"]), "🥳")
    }

    // MARK: - isSticky

    func test_isSticky_raisedHandFromAnyPlatform_returnsTrue() {
        XCTAssertTrue(CallReaction.dummy(type: ":raise-hand:").isSticky)
        XCTAssertTrue(CallReaction.dummy(type: "raised-hand").isSticky)
    }

    func test_isSticky_otherReaction_returnsFalse() {
        XCTAssertFalse(CallReaction.dummy(type: ":like:").isSticky)
    }
}
