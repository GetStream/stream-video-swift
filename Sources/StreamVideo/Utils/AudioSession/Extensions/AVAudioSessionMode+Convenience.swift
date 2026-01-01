//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - AVAudioSession.Mode

extension AVAudioSession.Mode {
    /// Returns the raw string value of the mode.
    public var description: String {
        rawValue
    }

    /// Indicates whether the mode keeps stereo playout active or if WebRTC
    /// should fall back to mono because of voice-processing constraints.
    var supportsStereoPlayout: Bool {
        switch self {
        case .videoChat, .voiceChat, .gameChat:
            return false

        default:
            return true
        }
    }
}
