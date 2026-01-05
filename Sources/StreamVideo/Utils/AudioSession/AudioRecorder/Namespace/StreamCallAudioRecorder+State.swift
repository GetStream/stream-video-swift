//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// The state structure for the call audio recording store.
    ///
    /// This state captures all aspects of the audio recording system,
    /// including the current recording status, interruption state, and
    /// audio levels.
    struct StoreState: Equatable {
        /// Indicates whether audio is currently being recorded.
        ///
        /// This reflects the actual recording state, which may differ from
        /// ``shouldRecord`` due to interruptions or permissions.
        var isRecording: Bool
        
        /// Indicates whether recording has been interrupted.
        ///
        /// Interruptions can occur from phone calls, other apps, or system
        /// events. When `true`, recording is paused even if ``shouldRecord``
        /// is `true`.
        var isInterrupted: Bool
        
        /// Indicates whether the system should be recording.
        ///
        /// This represents the desired recording state. The actual recording
        /// state (``isRecording``) may differ due to interruptions or lack
        /// of permissions.
        var shouldRecord: Bool
        
        /// The current audio meter level in decibels.
        ///
        /// Values typically range from -160 dB (silence) to 0 dB (maximum
        /// level). This value is updated frequently during recording to
        /// provide real-time audio level feedback.
        var meter: Float

        /// The initial state with all values set to their defaults.
        ///
        /// - `isRecording`: `false`
        /// - `isInterrupted`: `false`
        /// - `shouldRecord`: `false`
        /// - `meter`: `0`
        static let initial = State(
            isRecording: false,
            isInterrupted: false,
            shouldRecord: false,
            meter: 0
        )
    }
}
