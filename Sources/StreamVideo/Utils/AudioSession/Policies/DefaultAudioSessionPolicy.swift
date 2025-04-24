//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// A default implementation of the `AudioSessionPolicy` protocol.
public struct DefaultAudioSessionPolicy: AudioSessionPolicy {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    /// Initializes a new `DefaultAudioSessionPolicy` instance.
    public init() {}

    /// Returns the audio session configuration for the given call settings
    /// and own capabilities.
    ///
    /// - Parameters:
    ///   - callSettings: The current call settings.
    ///   - ownCapabilities: The set of the user's own audio capabilities.
    /// - Returns: The audio session configuration.
    public func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        guard applicationStateAdapter.state == .foreground else {
            return .init(
                category: .playAndRecord,
                mode: callSettings.videoOn ? .videoChat : .voiceChat,
                options: .playAndRecord(
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn,
                    appIsInForeground: false
                ),
                overrideOutputAudioPort: nil
            )
        }

        return .init(
            category: .playAndRecord,
            mode: callSettings.videoOn && callSettings.speakerOn ? .videoChat : .voiceChat,
            options: .playAndRecord(
                videoOn: callSettings.videoOn,
                speakerOn: callSettings.speakerOn,
                appIsInForeground: true
            ),
            overrideOutputAudioPort: callSettings.speakerOn ? .speaker : AVAudioSession.PortOverride.none
        )
    }
}
