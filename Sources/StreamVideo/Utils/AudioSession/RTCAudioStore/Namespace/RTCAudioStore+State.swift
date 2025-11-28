//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore {

    /// The state container for all permission statuses.
    struct StoreState: CustomStringConvertible, Encodable, Hashable, Sendable {

        struct StereoConfiguration: CustomStringConvertible, Encodable, Hashable, Sendable {
            struct Playout: CustomStringConvertible, Encodable, Hashable, Sendable {
                var preferred: Bool
                var enabled: Bool

                var description: String { "{ preferred:\(preferred), enabled:\(enabled) }" }
            }

            var playout: Playout

            var description: String {
                "{ playout:\(playout) }"
            }
        }

        struct AVAudioSessionConfiguration: CustomStringConvertible, Encodable, Hashable, Sendable {
            var category: AVAudioSession.Category
            /// The AVAudioSession mode. Encoded as its string value.
            var mode: AVAudioSession.Mode
            /// The AVAudioSession category options. Encoded as its raw value.
            var options: AVAudioSession.CategoryOptions
            /// The AVAudioSession port override. Encoded as its raw value.
            var overrideOutputAudioPort: AVAudioSession.PortOverride

            var description: String {
                " { " +
                    "category:\(category), " +
                    "mode:\(mode), " +
                    "options:\(options), " +
                    "overrideOutputAudioPort:\(overrideOutputAudioPort)" +
                    " }"
            }

            static func == (
                lhs: AVAudioSessionConfiguration,
                rhs: AVAudioSessionConfiguration
            ) -> Bool {
                lhs.category == rhs.category
                    && lhs.mode == rhs.mode
                    && lhs.options == rhs.options
                    && lhs.overrideOutputAudioPort == rhs.overrideOutputAudioPort
            }

            private enum CodingKeys: String, CodingKey {
                case category
                case mode
                case options
                case overrideOutputAudioPort
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(category.rawValue, forKey: .category)
                try container.encode(mode.rawValue, forKey: .mode)
                try container.encode(options.rawValue, forKey: .options)
                try container.encode(
                    overrideOutputAudioPort.rawValue,
                    forKey: .overrideOutputAudioPort
                )
            }

            init(
                category: AVAudioSession.Category,
                mode: AVAudioSession.Mode,
                options: AVAudioSession.CategoryOptions,
                overrideOutputAudioPort: AVAudioSession.PortOverride
            ) {
                self.category = category
                self.mode = mode
                self.options = options
                self.overrideOutputAudioPort = overrideOutputAudioPort
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(category.rawValue)
                hasher.combine(mode.rawValue)
                hasher.combine(options.rawValue)
                hasher.combine(overrideOutputAudioPort.rawValue)
            }
        }

        struct WebRTCAudioSessionConfiguration: CustomStringConvertible, Encodable, Hashable, Sendable {
            /// If true, audio is enabled.
            var isAudioEnabled: Bool
            /// If true, manual audio management is enabled.
            var useManualAudio: Bool
            var prefersNoInterruptionsFromSystemAlerts: Bool

            var description: String {
                " { " +
                    "isAudioEnabled:\(isAudioEnabled)" +
                    ", useManualAudio:\(useManualAudio)" +
                    ", prefersNoInterruptionsFromSystemAlerts:\(prefersNoInterruptionsFromSystemAlerts)" +
                    " }"
            }
        }

        struct AudioRoute: Hashable, CustomStringConvertible, Encodable, Sendable {

            struct Port: Hashable, CustomStringConvertible, Encodable, Sendable {
                private static let externalPorts: Set<AVAudioSession.Port> = [
                    .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .carAudio, .headphones
                ]

                private enum CodingKeys: String, CodingKey {
                    case type
                    case name
                    case id
                }

                var type: String
                var name: String
                var id: String

                var isExternal: Bool
                var isSpeaker: Bool
                var isReceiver: Bool
                var channels: Int

                let source: AVAudioSessionPortDescription?

                var description: String {
                    " { id:\(id), name:\(name), type:\(type) }"
                }

                init(_ source: AVAudioSessionPortDescription) {
                    self.type = source.portType.rawValue
                    self.name = source.portName
                    self.id = source.uid
                    self.isExternal = Self.externalPorts.contains(source.portType)
                    self.isSpeaker = source.portType == .builtInSpeaker
                    self.isReceiver = source.portType == .builtInReceiver
                    self.channels = source.channels?.endIndex ?? 0
                    self.source = source
                }

                init(
                    type: String,
                    name: String,
                    id: String,
                    isExternal: Bool,
                    isSpeaker: Bool,
                    isReceiver: Bool,
                    channels: Int
                ) {
                    self.type = type
                    self.name = name
                    self.id = id
                    self.isExternal = isExternal
                    self.isSpeaker = isSpeaker
                    self.isReceiver = isReceiver
                    self.channels = channels
                    self.source = nil
                }
            }

            let inputs: [Port]
            let outputs: [Port]
            let reason: AVAudioSession.RouteChangeReason

            var isExternal: Bool
            var isSpeaker: Bool
            var isReceiver: Bool

            var supportsStereoOutput: Bool
            var supportsStereoInput: Bool

            var description: String {
                var result = "{ "
                result += "inputs:\(inputs)"
                result += ", outputs:\(outputs)"
                result += ", reason:\(reason)"
                result += ", supportsStereoInput:\(supportsStereoInput)"
                result += ", supportsStereoOutput:\(supportsStereoOutput)"
                result += " }"
                return result
            }

            init(
                _ source: AVAudioSessionRouteDescription,
                reason: AVAudioSession.RouteChangeReason = .unknown
            ) {
                self.init(
                    inputs: source.inputs.map(Port.init),
                    outputs: source.outputs.map(Port.init),
                    reason: reason
                )
            }

            init(
                inputs: [Port],
                outputs: [Port],
                reason: AVAudioSession.RouteChangeReason = .unknown
            ) {
                self.inputs = inputs
                self.outputs = outputs
                self.reason = reason
                self.isExternal = outputs.first { $0.isExternal } != nil
                self.isSpeaker = outputs.first { $0.isSpeaker } != nil
                self.isReceiver = outputs.first { $0.isReceiver } != nil
                self.supportsStereoInput = inputs.first { $0.channels > 1 } != nil
                self.supportsStereoOutput = outputs.first { $0.channels > 1 } != nil
            }

            static let empty = AudioRoute(inputs: [], outputs: [])
        }

        var isActive: Bool
        var isInterrupted: Bool
        var isRecording: Bool
        var isMicrophoneMuted: Bool
        var hasRecordingPermission: Bool

        var audioDeviceModule: AudioDeviceModule?
        var currentRoute: AudioRoute

        var audioSessionConfiguration: AVAudioSessionConfiguration
        var webRTCAudioSessionConfiguration: WebRTCAudioSessionConfiguration
        var stereoConfiguration: StereoConfiguration

        var description: String {
            " { " +
                "isActive:\(isActive)" +
                ", isInterrupted:\(isInterrupted)" +
                ", isRecording:\(isRecording)" +
                ", isMicrophoneMuted:\(isMicrophoneMuted)" +
                ", hasRecordingPermission:\(hasRecordingPermission)" +
                ", audioSessionConfiguration:\(audioSessionConfiguration)" +
                ", webRTCAudioSessionConfiguration:\(webRTCAudioSessionConfiguration)" +
                ", stereoConfiguration:\(stereoConfiguration)" +
                ", audioDeviceModule:\(audioDeviceModule)" +
                ", currentRoute:\(currentRoute)" +
                " }"
        }

        private enum CodingKeys: String, CodingKey {
            case isActive
            case isInterrupted
            case isRecording
            case isMicrophoneMuted
            case hasRecordingPermission
            case audioSessionConfiguration
            case webRTCAudioSessionConfiguration
            case stereoConfiguration
            case audioDeviceModule
            case currentRoute
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isActive, forKey: .isActive)
            try container.encode(isInterrupted, forKey: .isInterrupted)
            try container.encode(isRecording, forKey: .isRecording)
            try container.encode(isMicrophoneMuted, forKey: .isMicrophoneMuted)
            try container.encode(
                hasRecordingPermission,
                forKey: .hasRecordingPermission
            )
            try container.encode(
                audioSessionConfiguration,
                forKey: .audioSessionConfiguration
            )
            try container.encode(
                webRTCAudioSessionConfiguration,
                forKey: .webRTCAudioSessionConfiguration
            )
            try container.encode(
                stereoConfiguration,
                forKey: .stereoConfiguration
            )
            try container.encodeIfPresent(
                audioDeviceModule,
                forKey: .audioDeviceModule
            )
            try container.encode(currentRoute, forKey: .currentRoute)
        }

        static func == (lhs: StoreState, rhs: StoreState) -> Bool {
            lhs.isActive == rhs.isActive
                && lhs.isInterrupted == rhs.isInterrupted
                && lhs.isRecording == rhs.isRecording
                && lhs.isMicrophoneMuted == rhs.isMicrophoneMuted
                && lhs.hasRecordingPermission == rhs.hasRecordingPermission
                && lhs.audioSessionConfiguration == rhs.audioSessionConfiguration
                && lhs.webRTCAudioSessionConfiguration == rhs.webRTCAudioSessionConfiguration
                && lhs.stereoConfiguration == rhs.stereoConfiguration
                && lhs.audioDeviceModule === rhs.audioDeviceModule
                && lhs.currentRoute == rhs.currentRoute
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isActive)
            hasher.combine(isInterrupted)
            hasher.combine(isRecording)
            hasher.combine(isMicrophoneMuted)
            hasher.combine(hasRecordingPermission)
            hasher.combine(audioSessionConfiguration)
            hasher.combine(webRTCAudioSessionConfiguration)
            hasher.combine(stereoConfiguration)
            if let audioDeviceModule {
                hasher.combine(ObjectIdentifier(audioDeviceModule))
            } else {
                hasher.combine(0 as UInt8)
            }
            hasher.combine(currentRoute)
        }
    }
}
