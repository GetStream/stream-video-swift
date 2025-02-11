//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

public struct DefaultAudioSessionPolicy: AudioSessionPolicy {

    public init() {}

    public func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        .init(
            category: .playAndRecord,
            mode: callSettings.speakerOn ? .videoChat : .voiceChat,
            options: .playAndRecord,
            overrideOutputAudioPort: callSettings.speakerOn ? .speaker : AVAudioSession.PortOverride.none
        )
    }
}
