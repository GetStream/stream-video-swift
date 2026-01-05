//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSession.CategoryOptions {
    /// Provides a description of the `CategoryOptions` set, listing each option
    /// contained within. This allows for easy logging and debugging of audio
    /// session configurations.
    public var description: String {
        // Initialize an empty array to hold the names of the options.
        var options: [String] = []

        // Check each specific category option to see if it is present in
        // `CategoryOptions`. If it is, append the corresponding name to the `options` array.

        // Adds ".mixWithOthers" if this option is present, allowing audio to mix
        // with other active audio sessions instead of interrupting them.
        if contains(.mixWithOthers) {
            options.append(".mixWithOthers")
        }

        // Adds ".duckOthers" if present, allowing other audio to temporarily
        // reduce volume when this session plays sound.
        if contains(.duckOthers) {
            options.append(".duckOthers")
        }

        #if canImport(AVFoundation, _version: 2360.61.4.11)
        // Adds ".allowBluetooth" if present, permitting audio playback through
        // Bluetooth devices.
        if contains(.allowBluetoothHFP) {
            options.append(".allowBluetoothHFP")
        }
        #else
        // Adds ".allowBluetooth" if present, permitting audio playback through
        // Bluetooth devices.
        if contains(.allowBluetooth) {
            options.append(".allowBluetooth")
        }
        #endif

        // Adds ".defaultToSpeaker" if present, enabling speaker output by default.
        if contains(.defaultToSpeaker) {
            options.append(".defaultToSpeaker")
        }

        // Adds ".interruptSpokenAudioAndMixWithOthers" if present, enabling this
        // session to interrupt other spoken audio content but still mix with others.
        if contains(.interruptSpokenAudioAndMixWithOthers) {
            options.append(".interruptSpokenAudioAndMixWithOthers")
        }

        // Adds ".allowBluetoothA2DP" if present, allowing audio output via
        // Bluetooth Advanced Audio Distribution Profile (A2DP) devices.
        if contains(.allowBluetoothA2DP) {
            options.append(".allowBluetoothA2DP")
        }

        // Adds ".allowAirPlay" if present, permitting audio playback through
        // AirPlay-compatible devices.
        if contains(.allowAirPlay) {
            options.append(".allowAirPlay")
        }

        // Checks if the `.overrideMutedMicrophoneInterruption` option is available
        // in iOS 14.5+ and adds it if present, allowing sessions to override
        // microphone interruptions when muted.
        if #available(iOS 14.5, *) {
            if contains(.overrideMutedMicrophoneInterruption) {
                options.append(".overrideMutedMicrophoneInterruption")
            }
        }

        // If no options were appended, return ".noOptions". Otherwise, join
        // the list of option names with commas for readability.
        return options.isEmpty ? ".noOptions" : options.joined(separator: ", ")
    }
}
