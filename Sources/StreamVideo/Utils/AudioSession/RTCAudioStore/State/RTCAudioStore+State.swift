//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {
    /// A value type representing the current state of the RTCAudioStore.
    ///
    /// This struct encapsulates all relevant audio session properties, including
    /// activation, interruption, permissions, and AVAudioSession configuration.
    /// Properties are explicitly encoded for diagnostics, analytics, or
    /// persistence. Non-encodable AVFoundation types are encoded using their
    /// string or raw value representations to ensure compatibility.
    ///
    /// - Note: Properties such as `category`, `mode`, `options`, and
    ///   `overrideOutputAudioPort` are encoded as their string or raw values.
    public struct State: Equatable, Encodable {

        /// Indicates if the audio session is currently active.
        public var isActive: Bool
        /// Indicates if the audio session is currently interrupted.
        public var isInterrupted: Bool
        /// If true, prefers no interruptions from system alerts.
        public var prefersNoInterruptionsFromSystemAlerts: Bool
        /// If true, audio is enabled.
        public var isAudioEnabled: Bool
        /// If true, manual audio management is enabled.
        public var useManualAudio: Bool
        /// The AVAudioSession category. Encoded as its string value.
        public var category: AVAudioSession.Category
        /// The AVAudioSession mode. Encoded as its string value.
        public var mode: AVAudioSession.Mode
        /// The AVAudioSession category options. Encoded as its raw value.
        public var options: AVAudioSession.CategoryOptions
        /// The AVAudioSession port override. Encoded as its raw value.
        public var overrideOutputAudioPort: AVAudioSession.PortOverride
        /// Indicates if the app has permission to record audio.
        public var hasRecordingPermission: Bool

        public var inputConfiguration: InputConfiguration

        /// The initial default state for the audio store.
        nonisolated(unsafe) static let initial = State(
            isActive: false,
            isInterrupted: false,
            prefersNoInterruptionsFromSystemAlerts: true,
            isAudioEnabled: false,
            useManualAudio: false,
            category: .playAndRecord,
            mode: .voiceChat,
            options: .allowBluetoothHFP,
            overrideOutputAudioPort: .none,
            hasRecordingPermission: false,
            inputConfiguration: .initial
        )

        /// Encodes this state into the given encoder.
        ///
        /// AVFoundation types are encoded as their string or raw value
        /// representations for compatibility.
        /// - Parameter encoder: The encoder to write data to.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isActive, forKey: .isActive)
            try container.encode(isInterrupted, forKey: .isInterrupted)
            try container.encode(prefersNoInterruptionsFromSystemAlerts, forKey: .prefersNoInterruptionsFromSystemAlerts)
            try container.encode(isAudioEnabled, forKey: .isAudioEnabled)
            try container.encode(useManualAudio, forKey: .useManualAudio)
            try container.encode(category.rawValue, forKey: .category)
            try container.encode(mode.rawValue, forKey: .mode)
            try container.encode(options.rawValue, forKey: .options)
            try container.encode(overrideOutputAudioPort.rawValue, forKey: .overrideOutputAudioPort)
            try container.encode(hasRecordingPermission, forKey: .hasRecordingPermission)
            try container.encode(inputConfiguration, forKey: .inputConfiguration)
        }

        /// Coding keys for encoding and decoding the state.
        private enum CodingKeys: String, CodingKey {
            case isActive
            case isInterrupted
            case prefersNoInterruptionsFromSystemAlerts
            case isAudioEnabled
            case useManualAudio
            case category
            case mode
            case options
            case overrideOutputAudioPort
            case hasRecordingPermission
            case inputConfiguration
        }
    }
}
