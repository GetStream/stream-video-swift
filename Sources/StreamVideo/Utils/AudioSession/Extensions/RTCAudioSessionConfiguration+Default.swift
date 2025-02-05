//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension AVAudioSession.CategoryOptions {

    static var playAndRecord: AVAudioSession.CategoryOptions = [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .allowAirPlay
    ]

    static var playback: AVAudioSession.CategoryOptions = [
    ]
}
