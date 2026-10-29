//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

extension String {
    public static let `default`: Self = "default"
    public static let development: Self = "development"
    public static let audioRoom: Self = "audio_room"
    public static let livestream: Self = "livestream"
    /// The built-in call type for voice calls with phone-call semantics: the
    /// call rings, is audio-only, and can't be reused once it has ended.
    public static let audioCall: Self = "audio_call"
    /// The built-in call type for conversations between a user and an AI
    /// agent: voice first, with continuous audio for the agent's turn
    /// detection, and can't be reused once it has ended.
    public static let agent: Self = "agent"
}
