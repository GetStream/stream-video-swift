//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamWebRTC

extension AVAudioSession.CategoryOptions {

    /// Category options for play and record.
    static let playAndRecord: AVAudioSession.CategoryOptions = [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .allowAirPlay
    ]

    /// Category options for playback.
    static let playback: AVAudioSession.CategoryOptions = []
}
