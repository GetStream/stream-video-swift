//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Represents the audio session configuration.
public struct AudioSessionConfiguration: CustomStringConvertible, Equatable, Sendable {
    var isActive: Bool
    /// The audio session category.
    var category: AVAudioSession.Category
    /// The audio session mode.
    var mode: AVAudioSession.Mode
    /// The audio session options.
    var options: AVAudioSession.CategoryOptions
    /// The audio session port override.
    var overrideOutputAudioPort: AVAudioSession.PortOverride?

    public var description: String {
        var result = "{ "
        result += "isActive:\(isActive)"
        result += ", category:\(category)"
        result += ", mode:\(mode)"
        result += ", options:\(options)"
        result += ", overrideOutputAudioPort:\(overrideOutputAudioPort)"
        result += " }"
        return result
    }

    /// Compares two `AudioSessionConfiguration` instances for equality.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isActive == rhs.isActive &&
            lhs.category == rhs.category &&
            lhs.mode == rhs.mode &&
            lhs.options.rawValue == rhs.options.rawValue &&
            lhs.overrideOutputAudioPort?.rawValue ==
            rhs.overrideOutputAudioPort?.rawValue
    }
}
