//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Represents the audio session configuration.
public struct AudioSessionConfiguration: ReflectiveStringConvertible,
    Equatable {
    /// The audio session category.
    var category: AVAudioSession.Category
    /// The audio session mode.
    var mode: AVAudioSession.Mode
    /// The audio session options.
    var options: AVAudioSession.CategoryOptions
    /// The audio session port override.
    var overrideOutputAudioPort: AVAudioSession.PortOverride?

    /// Compares two `AudioSessionConfiguration` instances for equality.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.category == rhs.category &&
            lhs.mode == rhs.mode &&
            lhs.options.rawValue == rhs.options.rawValue &&
            lhs.overrideOutputAudioPort?.rawValue ==
            rhs.overrideOutputAudioPort?.rawValue
    }
}
