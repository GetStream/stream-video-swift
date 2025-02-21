//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSession.PortOverride {
    /// Returns a string representing the port override value.
    public var description: String {
        switch self {
        case .none:
            return "None"
        case .speaker:
            return "Speaker"
        @unknown default:
            return "Unknown"
        }
    }
}
