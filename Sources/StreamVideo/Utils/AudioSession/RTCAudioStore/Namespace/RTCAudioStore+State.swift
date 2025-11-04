//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore {

    /// The state container for all permission statuses.
    public struct StoreState: CustomStringConvertible, Encodable, Hashable, Sendable {

        public enum RouteTransitionState: Encodable, Hashable, Sendable {
            case idle, updating
        }

        public struct AVAudioSessionConfiguration: CustomStringConvertible, Encodable, Hashable, Sendable {
            public var category: AVAudioSession.Category
            /// The AVAudioSession mode. Encoded as its string value.
            public var mode: AVAudioSession.Mode
            /// The AVAudioSession category options. Encoded as its raw value.
            public var options: AVAudioSession.CategoryOptions
            /// The AVAudioSession port override. Encoded as its raw value.
            public var overrideOutputAudioPort: AVAudioSession.PortOverride

            public var description: String {
                " { " +
                    "category:\(category), " +
                    "mode:\(mode), " +
                    "options:\(options), " +
                    "overrideOutputAudioPort:\(overrideOutputAudioPort)" +
                    " }"
            }

            public static func == (
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

            public func encode(to encoder: Encoder) throws {
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

            public func hash(into hasher: inout Hasher) {
                hasher.combine(category.rawValue)
                hasher.combine(mode.rawValue)
                hasher.combine(options.rawValue)
                hasher.combine(overrideOutputAudioPort.rawValue)
            }
        }

        public struct WebRTCAudioSessionConfiguration: CustomStringConvertible, Encodable, Hashable, Sendable {
            /// If true, audio is enabled.
            public var isAudioEnabled: Bool
            /// If true, manual audio management is enabled.
            public var useManualAudio: Bool
            public var prefersNoInterruptionsFromSystemAlerts: Bool

            public var description: String {
                " { " +
                    "isAudioEnabled:\(isAudioEnabled)" +
                    ", useManualAudio:\(useManualAudio)" +
                    ", prefersNoInterruptionsFromSystemAlerts:\(prefersNoInterruptionsFromSystemAlerts)" +
                    " }"
            }
        }

        public struct AudioRoute: Hashable, CustomStringConvertible, Encodable, Sendable {

            public struct Port: Hashable, CustomStringConvertible, Encodable, Sendable {
                private static let externalPorts: Set<AVAudioSession.Port> = [
                    .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .carAudio, .headphones
                ]

                public var type: String
                public var name: String
                public var id: String

                public var isExternal: Bool
                public var isSpeaker: Bool
                public var isReceiver: Bool
                public var channels: Int

                public var description: String {
                    " { id:\(id), name:\(name), type:\(type), channels:\(channels) }"
                }

                init(_ source: AVAudioSessionPortDescription) {
                    self.type = source.portType.rawValue
                    self.name = source.portName
                    self.id = source.uid
                    self.isExternal = Self.externalPorts.contains(source.portType)
                    self.isSpeaker = source.portType == .builtInSpeaker
                    self.isReceiver = source.portType == .builtInReceiver
                    self.channels = source.channels?.endIndex ?? 0
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
                }
            }

            public let inputs: [Port]
            public let outputs: [Port]
            let reason: AVAudioSession.RouteChangeReason

            public var isExternal: Bool
            public var isSpeaker: Bool
            public var isReceiver: Bool
            public var supportsStereoPlayout: Bool

            public var description: String {
                " { inputs:\(inputs), outputs:\(outputs), reason:\(reason) }"
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
                reason: AVAudioSession.RouteChangeReason
            ) {
                self.inputs = inputs
                self.outputs = outputs
                self.reason = reason
                self.isExternal = outputs.first { $0.isExternal } != nil
                self.isSpeaker = outputs.first { $0.isSpeaker } != nil
                self.isReceiver = outputs.first { $0.isReceiver } != nil
                self.supportsStereoPlayout = (outputs.first?.channels ?? 1) > 1
            }

            static let empty = AudioRoute(inputs: [], outputs: [], reason: .unknown)
        }

        public struct Stereo: Hashable, CustomStringConvertible, Encodable, Sendable {
            public var playoutAvailable: Bool
            public var playoutEnabled: Bool

            public var description: String {
                " { " +
                    "playoutAvailable:\(playoutAvailable)" +
                    ", playoutEnabled:\(playoutEnabled)" +
                    " }"
            }
        }

        public var isActive: Bool
        public var isInterrupted: Bool
        public var shouldRecord: Bool
        public var isRecording: Bool
        public var isMicrophoneMuted: Bool
        public var hasRecordingPermission: Bool
        public var speakerOutputChannels: Int
        public var receiverOutputChannels: Int

        var audioDeviceModule: AudioDeviceModule?
        public var routeTransitionState: RouteTransitionState
        public var currentRoute: AudioRoute

        public var stereo: Stereo

        public var audioSessionConfiguration: AVAudioSessionConfiguration
        public var webRTCAudioSessionConfiguration: WebRTCAudioSessionConfiguration

        public var description: String {
            " { " +
                "isActive:\(isActive)" +
                ", isInterrupted:\(isInterrupted)" +
                ", shouldRecord:\(shouldRecord)" +
                ", isRecording:\(isRecording)" +
                ", isMicrophoneMuted:\(isMicrophoneMuted)" +
                ", hasRecordingPermission:\(hasRecordingPermission)" +
                ", speakerOutputChannels:\(String(describing: speakerOutputChannels))" +
                ", receiverOutputChannels:\(String(describing: receiverOutputChannels))" +
                ", audioSessionConfiguration:\(audioSessionConfiguration)" +
                ", webRTCAudioSessionConfiguration:\(webRTCAudioSessionConfiguration)" +
                ", audioDeviceModule:\(audioDeviceModule)" +
                ", routeTransitionState:\(routeTransitionState)" +
                ", currentRoute:\(currentRoute)" +
                ", stereo:\(stereo)" +
                " }"
        }

        private enum CodingKeys: String, CodingKey {
            case isActive
            case isInterrupted
            case shouldRecord
            case isRecording
            case isMicrophoneMuted
            case hasRecordingPermission
            case speakerOutputChannels
            case receiverOutputChannels
            case audioSessionConfiguration
            case webRTCAudioSessionConfiguration
            case audioDeviceModule
            case routeTransitionState
            case currentRoute
            case stereo
        }

        public func encode(to encoder: Encoder) throws {
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
            try container.encodeIfPresent(
                speakerOutputChannels,
                forKey: .speakerOutputChannels
            )
            try container.encodeIfPresent(
                receiverOutputChannels,
                forKey: .receiverOutputChannels
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
            try container.encode(routeTransitionState, forKey: .routeTransitionState)
            try container.encode(currentRoute, forKey: .currentRoute)
            try container.encode(stereo, forKey: .stereo)
        }

        public static func == (lhs: StoreState, rhs: StoreState) -> Bool {
            lhs.isActive == rhs.isActive
                && lhs.isInterrupted == rhs.isInterrupted
                && lhs.shouldRecord == rhs.shouldRecord
                && lhs.isRecording == rhs.isRecording
                && lhs.isMicrophoneMuted == rhs.isMicrophoneMuted
                && lhs.hasRecordingPermission == rhs.hasRecordingPermission
                && lhs.speakerOutputChannels == rhs.speakerOutputChannels
                && lhs.receiverOutputChannels == rhs.receiverOutputChannels
                && lhs.audioSessionConfiguration == rhs.audioSessionConfiguration
                && lhs.webRTCAudioSessionConfiguration
                == rhs.webRTCAudioSessionConfiguration
                && lhs.audioDeviceModule === rhs.audioDeviceModule
                && lhs.routeTransitionState == rhs.routeTransitionState
                && lhs.currentRoute == rhs.currentRoute
                && lhs.stereo == rhs.stereo
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(isActive)
            hasher.combine(isInterrupted)
            hasher.combine(shouldRecord)
            hasher.combine(isRecording)
            hasher.combine(isMicrophoneMuted)
            hasher.combine(hasRecordingPermission)
            hasher.combine(speakerOutputChannels)
            hasher.combine(receiverOutputChannels)
            hasher.combine(audioSessionConfiguration)
            hasher.combine(webRTCAudioSessionConfiguration)
            if let audioDeviceModule {
                hasher.combine(ObjectIdentifier(audioDeviceModule))
            } else {
                hasher.combine(0 as UInt8)
            }
            hasher.combine(routeTransitionState)
            hasher.combine(currentRoute)
            hasher.combine(stereo)
        }
    }
}
