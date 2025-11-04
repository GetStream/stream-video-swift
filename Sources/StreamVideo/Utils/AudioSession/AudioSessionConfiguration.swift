//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Represents the audio session configuration.
public struct AudioSessionConfiguration: ReflectiveStringConvertible, Equatable, Sendable {
    var isActive: Bool
    /// The audio session category.
    var category: AVAudioSession.Category
    /// The audio session mode.
    var mode: AVAudioSession.Mode
    /// The audio session options.
    var options: AVAudioSession.CategoryOptions
    /// The audio session port override.
    var overrideOutputAudioPort: AVAudioSession.PortOverride?

    func withEnforcedStereoPlayoutOnExternalDevices(_ isEnforced: Bool) -> AudioSessionConfiguration {
        var newValue = self
        if isEnforced {
            newValue.options.remove(.allowBluetooth)
            newValue.options.insert(.allowBluetoothA2DP)
        } else if !isEnforced {
            newValue.options.insert(.allowBluetooth)
        }
        return newValue
    }

    func withStereoPlayoutCapableMode(
        _ state: RTCAudioStore.StoreState
    ) -> AudioSessionConfiguration {
        var newValue = self

        if state.currentRoute.supportsStereoPlayout {
            newValue.mode = .default
        } else if overrideOutputAudioPort == .speaker, state.speakerOutputChannels > 1 {
            newValue.mode = .default
        } else {
            /* No-op */
        }

        return newValue
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
