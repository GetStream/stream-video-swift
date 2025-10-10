//
//  RTCAudioStore+State.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import AVFoundation

extension RTCAudioStore {

    /// The state container for all permission statuses.
    struct StoreState: CustomStringConvertible, Encodable, Hashable, Sendable {

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

            static func ==(
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

                var type: String
                var name: String
                var id: String

                var isExternal: Bool
                var isSpeaker: Bool
                var isReceiver: Bool

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
                }
            }

            let inputs: [Port]
            let outputs: [Port]

            var isExternal: Bool
            var isSpeaker: Bool
            var isReceiver: Bool

            var description: String {
                " { inputs:\(inputs), outputs:\(outputs) }"
            }

            init(_ source: AVAudioSessionRouteDescription) {
                self.init(
                    inputs: source.inputs.map(Port.init),
                    outputs: source.outputs.map(Port.init)
                )
            }

            private init (
                inputs: [Port],
                outputs: [Port]
            ) {
                self.inputs = inputs
                self.outputs = outputs
                self.isExternal = outputs.first { $0.isExternal } != nil
                self.isSpeaker = outputs.first { $0.isSpeaker } != nil
                self.isReceiver = outputs.first { $0.isReceiver } != nil
            }

            static let empty = AudioRoute(inputs: [], outputs: [])
        }

        var isActive: Bool
        var isInterrupted: Bool
        var shouldRecord: Bool
        var isRecording: Bool
        var isMicrophoneMuted: Bool
        var hasRecordingPermission: Bool

        var audioDeviceModule: AudioDeviceModule?
        var currentRoute: AudioRoute

        var audioSessionConfiguration: AVAudioSessionConfiguration
        var webRTCAudioSessionConfiguration: WebRTCAudioSessionConfiguration

        var description: String {
            " { " +
            "isActive:\(isActive)" +
            ", isInterrupted:\(isInterrupted)" +
            ", shouldRecord:\(shouldRecord)" +
            ", isRecording:\(isRecording)" +
            ", isMicrophoneMuted:\(isMicrophoneMuted)" +
            ", hasRecordingPermission:\(hasRecordingPermission)" +
            ", audioSessionConfiguration:\(audioSessionConfiguration)" +
            ", webRTCAudioSessionConfiguration:\(webRTCAudioSessionConfiguration)" +
            ", audioDeviceModule:\(audioDeviceModule)" +
            ", currentRoute:\(currentRoute)" +
            " }"
        }

        private enum CodingKeys: String, CodingKey {
            case isActive
            case isInterrupted
            case shouldRecord
            case isRecording
            case isMicrophoneMuted
            case hasRecordingPermission
            case audioSessionConfiguration
            case webRTCAudioSessionConfiguration
            case audioDeviceModule
            case currentRoute
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isActive, forKey: .isActive)
            try container.encode(isInterrupted, forKey: .isInterrupted)
            try container.encode(shouldRecord, forKey: .shouldRecord)
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
            try container.encodeIfPresent(
                audioDeviceModule,
                forKey: .audioDeviceModule
            )
            try container.encode(currentRoute, forKey: .currentRoute)
        }

        static func == (lhs: StoreState, rhs: StoreState) -> Bool {
            lhs.isActive == rhs.isActive
            && lhs.isInterrupted == rhs.isInterrupted
            && lhs.shouldRecord == rhs.shouldRecord
            && lhs.isRecording == rhs.isRecording
            && lhs.isMicrophoneMuted == rhs.isMicrophoneMuted
            && lhs.hasRecordingPermission == rhs.hasRecordingPermission
            && lhs.audioSessionConfiguration == rhs.audioSessionConfiguration
            && lhs.webRTCAudioSessionConfiguration
                == rhs.webRTCAudioSessionConfiguration
            && lhs.audioDeviceModule === rhs.audioDeviceModule
            && lhs.currentRoute == rhs.currentRoute
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isActive)
            hasher.combine(isInterrupted)
            hasher.combine(shouldRecord)
            hasher.combine(isRecording)
            hasher.combine(isMicrophoneMuted)
            hasher.combine(hasRecordingPermission)
            hasher.combine(audioSessionConfiguration)
            hasher.combine(webRTCAudioSessionConfiguration)
            if let audioDeviceModule {
                hasher.combine(ObjectIdentifier(audioDeviceModule))
            } else {
                hasher.combine(0 as UInt8)
            }
            hasher.combine(currentRoute)
        }
    }
}
