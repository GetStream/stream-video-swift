//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore.StoreState.AVAudioSessionConfiguration {

    /// Indicates whether the configuration is part of the documented
    /// allowlist of `AVAudioSession` combinations.
    var isValid: Bool {
        Self.validate(
            category: category,
            mode: mode,
            options: options
        )
    }
}

extension RTCAudioStore.StoreState.AVAudioSessionConfiguration {

    private struct AllowedConfiguration {
        let modes: Set<AVAudioSession.Mode>
        let options: AVAudioSession.CategoryOptions
    }

    // Authoritative allow‑list per Apple documentation.
    private static let allowedConfigurations: [AVAudioSession.Category: AllowedConfiguration] = {
        var map: [AVAudioSession.Category: AllowedConfiguration] = [:]

        func makeModes(_ modes: [AVAudioSession.Mode]) -> Set<AVAudioSession.Mode> {
            Set(modes)
        }

        // .playback
        var playbackModes: Set<AVAudioSession.Mode> = makeModes(
            [
                .default,
                .moviePlayback,
                .spokenAudio
            ]
        )
        if #available(iOS 15.0, *) { playbackModes.insert(.voicePrompt) }
        map[.playback] = AllowedConfiguration(
            modes: playbackModes,
            options: [
                .mixWithOthers,
                .duckOthers,
                .interruptSpokenAudioAndMixWithOthers,
                .defaultToSpeaker,
                .allowBluetoothA2DP
            ]
        )

        // .playAndRecord
        var playAndRecordModes: Set<AVAudioSession.Mode> =
            makeModes(
                [
                    .default,
                    .voiceChat,
                    .videoChat,
                    .gameChat,
                    .videoRecording,
                    .measurement,
                    .spokenAudio
                ]
            )
        if #available(iOS 15.0, *) { playAndRecordModes.insert(.voicePrompt) }
        var playAndRecordOptions: AVAudioSession.CategoryOptions =
            [
                .mixWithOthers,
                .duckOthers,
                .interruptSpokenAudioAndMixWithOthers,
                .defaultToSpeaker,
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        map[.playAndRecord] = AllowedConfiguration(
            modes: playAndRecordModes,
            options: playAndRecordOptions
        )

        // .record
        map[.record] = AllowedConfiguration(
            modes: makeModes([.default, .measurement]),
            options: [.duckOthers]
        )

        // .multiRoute
        var multiRouteOptions: AVAudioSession.CategoryOptions = [.mixWithOthers]
        map[.multiRoute] = AllowedConfiguration(
            modes: makeModes([.default, .measurement]),
            options: multiRouteOptions
        )

        // .ambient / .soloAmbient
        let ambientOptions: AVAudioSession.CategoryOptions =
            [.mixWithOthers, .duckOthers, .interruptSpokenAudioAndMixWithOthers]
        map[.ambient] = AllowedConfiguration(
            modes: makeModes([.default]),
            options: ambientOptions
        )
        map[.soloAmbient] = AllowedConfiguration(
            modes: makeModes([.default]),
            options: ambientOptions
        )

        return map
    }()

    /// Validates a combination of category, mode, and options against the
    /// allowlist derived from Apple's documentation.
    private static func validate(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) -> Bool {
        guard let allowed = allowedConfigurations[category] else {
            return false
        }
        guard allowed.modes.contains(mode) else {
            return false
        }
        guard allowed.options.contains(options) else {
            return false
        }
        return true
    }
}
