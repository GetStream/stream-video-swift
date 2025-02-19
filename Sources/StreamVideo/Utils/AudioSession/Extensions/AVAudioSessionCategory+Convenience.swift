//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - AVAudioSession.Category

extension AVAudioSession.Category: @retroactive CustomStringConvertible {
    /// Returns the raw string value of the category.
    public var description: String {
        rawValue
    }
}
