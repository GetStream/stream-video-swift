//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - AVAudioSession.Category

extension AVAudioSession.Category {
    /// Returns the raw string value of the category.
    public var description: String {
        rawValue
    }

    var isOverrideOutputPortSupported: Bool {
        switch self {
        case .playback, .playAndRecord:
            return true
        default:
            return false
        }
    }
}
