//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// A default implementation of the `AudioSessionPolicy` protocol.
public struct DefaultAudioSessionPolicy: AudioSessionPolicy {

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
        .init(
            category: .playAndRecord,
            mode: callSettings.videoOn ? .videoChat : .voiceChat,
            options: .playAndRecord,
            overrideOutputAudioPort: callSettings.speakerOn ? .speaker : AVAudioSession.PortOverride.none
        )
    }
}
