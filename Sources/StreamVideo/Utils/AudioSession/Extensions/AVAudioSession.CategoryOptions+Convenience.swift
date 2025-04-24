//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamWebRTC

extension AVAudioSession.CategoryOptions {

    /// Category options for play and record.
    static func playAndRecord(
        videoOn: Bool,
        speakerOn: Bool,
        appIsInForeground: Bool
    ) -> AVAudioSession.CategoryOptions {
        var result: AVAudioSession.CategoryOptions = [
            .allowBluetooth,
            .allowBluetoothA2DP,
            .allowAirPlay
        ]

        /// - Note:We only add the `defaultToSpeaker` if the following are true:
        /// - It's required (speakerOn = true)
        /// - The app is foregrounded. The reason is that while in CallKit port overrides are being treated
        /// as hard overrides and stop CallKit Speaker button from allowing the user to toggle it off.
        if !videoOn, speakerOn, appIsInForeground {
            result.insert(.defaultToSpeaker)
        }

        return result
    }

    /// Category options for playback.
    static let playback: AVAudioSession.CategoryOptions = []
}
