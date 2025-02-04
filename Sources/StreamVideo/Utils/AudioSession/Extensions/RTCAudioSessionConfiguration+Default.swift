//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCAudioSessionConfiguration {
    /// Provides a default configuration for `RTCAudioSessionConfiguration`
    /// tailored for WebRTC audio sessions, setting it to be suitable for
    /// both playback and recording.
    static let `default`: RTCAudioSessionConfiguration = {
        // Creates a new WebRTC-specific audio session configuration instance.
        let configuration = RTCAudioSessionConfiguration.webRTC()

        // Sets the audio mode to the default system mode. This typically
        // configures the session to use system default settings for
        // playback and recording.
        configuration.mode = AVAudioSession.Mode.videoChat.rawValue

        // Sets the audio category to `.playAndRecord`, enabling the session
        // to handle both audio playback and recording simultaneously.
        // This category is commonly used in applications that require
        // two-way audio, like video calls.
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue

        configuration.categoryOptions = .playAndRecord

        // Returns the fully configured default WebRTC audio session
        // configuration.
        return configuration
    }()
}

extension AVAudioSession.CategoryOptions {

    static var playAndRecord: AVAudioSession.CategoryOptions = [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .allowAirPlay
    ]

    static var playback: AVAudioSession.CategoryOptions = [
    ]
}
