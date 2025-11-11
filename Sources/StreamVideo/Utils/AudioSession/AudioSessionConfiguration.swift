//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    func withStereoPlayoutMode(
        _ mode: StereoPlayoutMode,
        currentRoute: RTCAudioStore.StoreState.AudioRoute
    ) -> AudioSessionConfiguration {
        var update = self
        update.rewriteModeForStereoIfRequired(mode, currentRoute: currentRoute)
        update.rewriteCategoryOptionsForStereoIfRequired(mode)
        return update
    }

    // MARK: - Private helpers

    private mutating func rewriteModeForStereoIfRequired(
        _ playoutMode: StereoPlayoutMode,
        currentRoute: RTCAudioStore.StoreState.AudioRoute
    ) {
        switch playoutMode {
        case .none:
            break
        case .deviceOnly:
            if overrideOutputAudioPort == .speaker {
                mode = .default
            } else if currentRoute.isReceiver, currentRoute.supportsStereoOutput {
                mode = .default
            }
        case .externalOnly:
            if currentRoute.isExternal, currentRoute.supportsStereoOutput {
                mode = .default
            }
        case .deviceAndExternal:
            if overrideOutputAudioPort == .speaker {
                mode = .default
            } else if currentRoute.isReceiver, currentRoute.supportsStereoOutput {
                mode = .default
            } else if currentRoute.isExternal, currentRoute.supportsStereoOutput {
                mode = .default
            }
        }
    }

    private mutating func rewriteCategoryOptionsForStereoIfRequired(
        _ playoutMode: StereoPlayoutMode
    ) {
        switch playoutMode {
        case .none:
            break
        case .deviceOnly:
            break
        case .externalOnly:
            options.remove(.allowBluetoothHFP)
        case .deviceAndExternal:
            options.remove(.allowBluetoothHFP)
        }
    }
}
