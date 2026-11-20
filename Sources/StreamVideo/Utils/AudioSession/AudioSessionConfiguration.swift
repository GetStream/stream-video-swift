//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// How voice processing attenuates the app's other audio during a call.
///
/// The values match `AVAudioVoiceProcessingOtherAudioDuckingConfiguration`.
/// The audio engine applies them while voice processing and capture are on.
/// That requires iOS 17 or macOS 14. Older systems, and tvOS, keep the
/// engine default. Music mode and stereo playout turn voice processing off,
/// so this configuration has no effect in those modes.
///
/// ``platformDefault`` matches the engine before a policy changes it:
/// advanced ducking on, level ``Level/default``.
public struct OtherAudioDuckingConfiguration: Equatable, Sendable, CustomStringConvertible {

    /// How far voice processing attenuates other audio.
    ///
    /// Raw values match `AVAudioVoiceProcessingOtherAudioDuckingLevel`.
    /// ``min`` leaves other audio loudest. ``max`` attenuates it most.
    public enum Level: Int, Equatable, Sendable {
        case `default` = 0
        case min = 10
        case mid = 20
        case max = 30
    }

    /// Attenuation applied to other audio.
    public let level: Level

    /// Ducks other audio only while local or remote voice is active.
    public let isAdvancedDuckingEnabled: Bool

    public var description: String {
        "{ level:\(level.rawValue), isAdvancedDuckingEnabled:\(isAdvancedDuckingEnabled) }"
    }

    /// The engine's ducking before a policy changes it.
    public static let platformDefault = OtherAudioDuckingConfiguration()

    /// Creates a ducking configuration.
    ///
    /// - Parameters:
    ///   - level: Attenuation applied to other audio.
    ///   - isAdvancedDuckingEnabled: Duck only during voice activity.
    public init(
        level: Level = .default,
        isAdvancedDuckingEnabled: Bool = true
    ) {
        self.level = level
        self.isAdvancedDuckingEnabled = isAdvancedDuckingEnabled
    }
}

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
    /// How voice processing ducks the app's other audio.
    ///
    /// The default matches the audio engine's current ducking.
    var otherAudioDucking: OtherAudioDuckingConfiguration

    public var description: String {
        var result = "{ "
        result += "isActive:\(isActive)"
        result += ", category:\(category.description)"
        result += ", mode:\(mode.description)"
        result += ", options:\(options.description)"
        result += ", overrideOutputAudioPort:\(overrideOutputAudioPort?.description ?? ".none")"
        result += ", otherAudioDucking:\(otherAudioDucking)"
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
    ///   - otherAudioDucking: How voice processing ducks the app's
    ///     other audio. The default matches the current engine.
    public init(
        isActive: Bool,
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions,
        overrideOutputAudioPort: AVAudioSession.PortOverride? = nil,
        otherAudioDucking: OtherAudioDuckingConfiguration = .platformDefault
    ) {
        self.isActive = isActive
        self.category = category
        self.mode = mode
        self.options = options
        self.overrideOutputAudioPort = overrideOutputAudioPort
        self.otherAudioDucking = otherAudioDucking
    }

    /// Compares two `AudioSessionConfiguration` instances for equality.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isActive == rhs.isActive &&
            lhs.category == rhs.category &&
            lhs.mode == rhs.mode &&
            lhs.options.rawValue == rhs.options.rawValue &&
            lhs.overrideOutputAudioPort?.rawValue ==
            rhs.overrideOutputAudioPort?.rawValue &&
            lhs.otherAudioDucking == rhs.otherAudioDucking
    }
}
