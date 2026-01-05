//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Actions that can be dispatched to the call audio recording store.
    ///
    /// These actions represent state changes in the audio recording system
    /// and are processed by reducers and middleware to update the store's
    /// state.
    enum StoreAction: Sendable, Equatable, StoreActionBoxProtocol {
        /// Sets whether audio recording is currently active.
        ///
        /// - Parameter isRecording: `true` if recording is active, `false`
        ///   otherwise.
        case setIsRecording(Bool)
        
        /// Sets whether audio recording has been interrupted.
        ///
        /// Interruptions can occur due to phone calls, other apps taking
        /// audio focus, or system events.
        ///
        /// - Parameter isInterrupted: `true` if recording is interrupted,
        ///   `false` when the interruption ends.
        case setIsInterrupted(Bool)
        
        /// Sets whether the system should be recording audio.
        ///
        /// This represents the desired recording state, which may differ
        /// from the actual recording state due to interruptions or
        /// permissions.
        ///
        /// - Parameter shouldRecord: `true` if recording should be active,
        ///   `false` otherwise.
        case setShouldRecord(Bool)
        
        /// Updates the current audio meter level.
        ///
        /// The meter value represents the average power level in decibels
        /// for the audio being recorded.
        ///
        /// - Parameter meter: The current audio level in decibels (dB).
        ///   Typical range is from -160 dB (silence) to 0 dB (maximum).
        case setMeter(Float)
    }
}
