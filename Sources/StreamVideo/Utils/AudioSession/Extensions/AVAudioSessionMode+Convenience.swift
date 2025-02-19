//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - AVAudioSession.Mode

extension AVAudioSession.Mode: @retroactive CustomStringConvertible {
    /// Returns the raw string value of the mode.
    public var description: String {
        rawValue
    }
}
