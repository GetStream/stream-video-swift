//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStoreAction {

    /// An action describing a CallKit-driven change to the AVAudioSession.
    ///
    /// Use this enum to represent explicit audio session activation and deactivation
    /// events that are triggered by CallKit and should be handled by the reducer.
    enum CallKit {
        /// Indicates that the audio session was activated via CallKit.
        case activate(AVAudioSession)

        /// Indicates that the audio session was deactivated via CallKit.
        case deactivate(AVAudioSession)
    }
}
