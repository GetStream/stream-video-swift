//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStoreAction {

    /// Enumerates the supported actions for audio session state changes.
    ///
    /// Use these cases to express updates and configuration changes to the
    /// audio session, including activation, interruption, category, output
    /// port, and permissions.
    enum AudioSession {
        /// Activates or deactivates the audio session.
        case isActive(Bool)

        /// Sets the interruption state of the audio session.
        case isInterrupted(Bool)

        /// Enables or disables audio.
        case isAudioEnabled(Bool)

        /// Enables or disables manual audio management.
        case useManualAudio(Bool)

        /// Sets the session category, mode, and options.
        case setCategory(
            AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            options: AVAudioSession.CategoryOptions
        )

        /// Overrides the output audio port (e.g., speaker, none).
        case setOverrideOutputPort(AVAudioSession.PortOverride)

        /// Sets whether system alerts should not interrupt the session.
        case setPrefersNoInterruptionsFromSystemAlerts(Bool)

        /// Sets the recording permission state for the session.
        case setHasRecordingPermission(Bool)

        /// Used when activating/deactivating audioOutput from CallSettings.
        /// - Warning: It has the potential to cause misalignment with the underline RTCAudioSession.
        /// It should be used with caution.
        case setAVAudioSessionActive(Bool)

        case setAudioDeviceModule(AudioDeviceModule?)
    }
}
