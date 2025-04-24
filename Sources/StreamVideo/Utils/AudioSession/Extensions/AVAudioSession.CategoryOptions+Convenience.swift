//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamWebRTC

extension AVAudioSession.CategoryOptions {

    /// Category options for play and record.
    static func playAndRecord(videoOn: Bool, speakerOn: Bool, appIsInForeground: Bool) -> AVAudioSession.CategoryOptions {
        var result: AVAudioSession.CategoryOptions = [
            .allowBluetooth,
            .allowBluetoothA2DP,
            .allowAirPlay
        ]

        if !videoOn, speakerOn, appIsInForeground {
            result.insert(.defaultToSpeaker)
        }

        return result
    }

    /// Category options for playback.
    static let playback: AVAudioSession.CategoryOptions = []
}
