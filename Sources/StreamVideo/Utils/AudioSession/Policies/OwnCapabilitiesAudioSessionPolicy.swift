//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// An audio session policy that considers the users's own capabilities.
/// By using this category, you can allow users that don't have the `sendAudio` capability (e.g. livestream
/// watchers) or their `CallSettings` doesn't require the `playAndRecord` category, to mute completely
/// the audio - while they remain in call - by using the device's physical buttons on `ControlCentre`
///
/// - Note: This policy defaults to  `playback` category if the user does
/// not have the `sendAudio` capability. If the user has the `sendAudio`
/// capability, then the policy switches between `playback` and `playAndRecord`
/// based on the following criteria:
/// - `CallSettings.audioOn == true` or `CallSettings.speakerOn == true and
// currentDevice has earpiece`: we use `playAndRecord` category.
/// - Otherwise we use `playback` category.
public struct OwnCapabilitiesAudioSessionPolicy: AudioSessionPolicy {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.currentDevice) private var currentDevice

    /// Initializes a new `OwnCapabilitiesAudioSessionPolicy` instance.
    public init() {}

    /// Returns the audio session configuration based on call settings and
    /// user capabilities.
    ///
    /// - Parameters:
    ///   - callSettings: The current call settings.
    ///   - ownCapabilities: The set of the user's own capabilities.
    /// - Returns: The audio session configuration.
    public func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        guard ownCapabilities.contains(.sendAudio) else {
            return .init(
                isActive: callSettings.audioOutputOn,
                category: .playback,
                mode: .default,
                options: .playback,
                overrideOutputAudioPort: nil
            )
        }

        let currentDeviceHasEarpiece = CurrentDevice
            .currentValue
            .deviceType == .phone

        let category: AVAudioSession.Category = callSettings.audioOn
            || (callSettings.speakerOn && currentDeviceHasEarpiece)
            ? .playAndRecord
            : .playback

        let mode: AVAudioSession.Mode = category == .playAndRecord
            ? .voiceChat
            : .default

        let categoryOptions: AVAudioSession.CategoryOptions = category == .playAndRecord
            ? .playAndRecord(
                videoOn: callSettings.videoOn,
                speakerOn: callSettings.speakerOn,
                appIsInForeground: applicationStateAdapter.state == .foreground
            )
            : .playback

        let overrideOutputAudioPort: AVAudioSession.PortOverride? = category == .playAndRecord && applicationStateAdapter
            .state == .foreground
            ? callSettings.speakerOn == true ? .speaker : AVAudioSession.PortOverride.none
            : nil

        return .init(
            isActive: callSettings.audioOutputOn,
            category: category,
            mode: mode,
            options: categoryOptions,
            overrideOutputAudioPort: overrideOutputAudioPort
        )
    }
}
