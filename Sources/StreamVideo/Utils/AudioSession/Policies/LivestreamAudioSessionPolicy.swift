//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct LivestreamAudioSessionPolicy: AudioSessionPolicy {

    public init() {}

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
