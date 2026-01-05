//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSessionRouteDescription {

    override open var description: String {
        let inputTypes = inputs.map(\.portType.rawValue).joined(separator: ",")
        let outputTypes = outputs.map(\.portType.rawValue).joined(separator: ",")
        let wrapperKey = isExternal ? ".external" : ".builtIn"
        return [
            wrapperKey,
            "(",
            ["inputs:\(inputTypes)", "outputs:\(outputTypes)"].joined(separator: ", "),
            ")"
        ].joined()
    }

    /// A set of port types that represent external audio outputs, such as
    /// Bluetooth and car audio systems. These are used to determine if
    /// the route includes an external output device.
    private static let externalPorts: Set<AVAudioSession.Port> = [
        .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .carAudio, .headphones
    ]

    /// A Boolean value indicating whether the audio output is external.
    /// Checks if any of the output port types match the defined set of
    /// `externalPorts`.
    var isExternal: Bool {
        // Maps the port types of each output and checks if any are within
        // the `externalPorts` set.
        outputs.map(\.portType).contains { Self.externalPorts.contains($0) }
    }

    /// A Boolean value indicating if the output is directed to the built-in
    /// speaker of the device.
    var isSpeaker: Bool {
        // Maps the output port types and checks if any type is `.builtInSpeaker`.
        outputs.map(\.portType).contains { $0 == .builtInSpeaker }
    }

    /// A Boolean value indicating if the output is directed to the built-in
    /// receiver (typically used for in-ear audio).
    var isReceiver: Bool {
        // Maps the output port types and checks if any type is `.builtInReceiver`.
        outputs.map(\.portType).contains { $0 == .builtInReceiver }
    }

    /// A comma-separated string listing the types of all output ports.
    /// Useful for logging the specific types of outputs currently in use.
    var outputTypes: String {
        // Maps each output port type to its raw string value and joins them
        // with commas to create a readable output list.
        outputs
            .map(\.portType.rawValue)
            .joined(separator: ",")
    }
}
