//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides an audio session configuration tailored for livestream calls,
/// keeping stereo playout active while respecting the local capabilities.
public struct LivestreamAudioSessionPolicy: AudioSessionPolicy {

    public init() {}

    /// Builds the configuration used when a call toggles livestream mode.
    /// Stereo playout is preferred, but the policy falls back to playback if
    /// the current user cannot transmit audio.
    public func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        .init(
            isActive: callSettings.audioOutputOn,
            category: ownCapabilities.contains(.sendAudio) ? .playAndRecord : .playback,
            mode: .default,
            options: .allowBluetoothA2DP,
            overrideOutputAudioPort: callSettings.speakerOn ? .speaker : nil
        )
    }
}
