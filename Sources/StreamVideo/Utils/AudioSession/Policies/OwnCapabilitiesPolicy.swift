//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

public struct OwnCapabilitiesAudioSessionPolicy: AudioSessionPolicy {

    private let currentDevice = CurrentDevice.currentValue

    public init() {}

    public func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        guard ownCapabilities.contains(.sendAudio) else {
            return .init(
                category: .playback,
                mode: .default,
                options: .playback,
                overrideOutputAudioPort: nil
            )
        }

        let currentDeviceHasEarpiece = currentDevice.deviceType == .phone

        let category: AVAudioSession.Category = callSettings.audioOn
            || (callSettings.speakerOn && currentDeviceHasEarpiece)
            ? .playAndRecord
            : .playback

        let mode: AVAudioSession.Mode = category == .playAndRecord
            ? callSettings.speakerOn ? .videoChat : .voiceChat
            : .default

        let categoryOptions: AVAudioSession.CategoryOptions = category == .playAndRecord
            ? .playAndRecord
            : .playback

        let overrideOutputAudioPort: AVAudioSession.PortOverride? = category == .playAndRecord
            ? callSettings.speakerOn == true ? .speaker : AVAudioSession.PortOverride.none
            : nil

        return .init(
            category: category,
            mode: mode,
            options: categoryOptions,
            overrideOutputAudioPort: overrideOutputAudioPort
        )
    }
}
