//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSession.PortOverride {
    /// Returns a string representing the port override value.
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case .speaker:
            return ".speaker"
        @unknown default:
            return ".unknown"
        }
    }
}
