//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - AVAudioSession.Mode

extension AVAudioSession.Mode {
    /// Returns the raw string value of the mode.
    public var description: String {
        rawValue
    }

    var supportsStereoPlayout: Bool {
        switch self {
        case .videoChat, .voiceChat, .gameChat:
            return false
        default:
            return true
        }
    }
}
