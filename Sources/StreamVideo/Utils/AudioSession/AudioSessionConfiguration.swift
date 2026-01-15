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

    /// Creates a new audio session configuration.
    ///
    /// - Parameters:
    ///   - isActive: Whether the audio session should be active.
    ///   - category: The audio session category.
    ///   - mode: The audio session mode.
    ///   - options: The audio session category options.
    ///   - overrideOutputAudioPort: The audio session port override.
    public init(
        isActive: Bool,
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions,
        overrideOutputAudioPort: AVAudioSession.PortOverride? = nil
    ) {
        self.isActive = isActive
        self.category = category
        self.mode = mode
        self.options = options
        self.overrideOutputAudioPort = overrideOutputAudioPort
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
