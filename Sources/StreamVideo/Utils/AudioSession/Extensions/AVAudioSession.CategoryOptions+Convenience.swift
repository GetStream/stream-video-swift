//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        [
            .allowBluetoothHFP,
            .allowBluetoothA2DP
        ]
    }

    /// Category options for playback.
    static let playback: AVAudioSession.CategoryOptions = []

    #if !canImport(AVFoundation, _version: 2360.61.4.11)
    /// Older SDKs only expose ``allowBluetooth`` so we map the HFP alias to it
    /// to avoid peppering the codebase with availability checks.
    public static let allowBluetoothHFP = Self.allowBluetooth
    #endif
}
