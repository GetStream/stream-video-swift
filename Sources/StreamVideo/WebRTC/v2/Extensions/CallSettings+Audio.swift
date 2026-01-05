//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Extension adding audio settings to `CallSettings`.
extension CallSettings {

    /// Represents audio settings for a call.
    ///
    /// This structure encapsulates the state of the microphone, speaker, and audio session.
    struct Audio: Equatable {
        /// Indicates whether the microphone is on.
        var micOn: Bool
        /// Indicates whether the speaker is on.
        var speakerOn: Bool
        /// Indicates whether the audio session is active.
        var audioSessionOn: Bool
    }

    /// Provides the current audio settings.
    ///
    /// This computed property returns an `Audio` instance representing the current
    /// state of the microphone, speaker, and audio session.
    var audio: Audio {
        .init(
            micOn: audioOn,
            speakerOn: speakerOn,
            audioSessionOn: audioOutputOn
        )
    }
}
