//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class AudioSettingsDefaultDevice: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let earpiece = AudioSettingsDefaultDevice(rawValue: "earpiece")
    public static let speaker = AudioSettingsDefaultDevice(rawValue: "speaker")
}

public final class AudioSettings: Sendable, Decodable {
    public let accessRequestEnabled: Bool
    public let defaultDevice: AudioSettingsDefaultDevice
    public let hifiAudioEnabled: Bool?
    public let micDefaultOn: Bool
    public let noiseCancellation: NoiseCancellationSettingsRequest?
    public let opusDtxEnabled: Bool
    public let redundantCodingEnabled: Bool
    public let speakerDefaultOn: Bool

    public init(
        accessRequestEnabled: Bool,
        defaultDevice: AudioSettingsDefaultDevice,
        hifiAudioEnabled: Bool? = nil,
        micDefaultOn: Bool,
        noiseCancellation: NoiseCancellationSettingsRequest? = nil,
        opusDtxEnabled: Bool,
        redundantCodingEnabled: Bool,
        speakerDefaultOn: Bool
    ) {
        self.accessRequestEnabled = accessRequestEnabled
        self.defaultDevice = defaultDevice
        self.hifiAudioEnabled = hifiAudioEnabled
        self.micDefaultOn = micDefaultOn
        self.noiseCancellation = noiseCancellation
        self.opusDtxEnabled = opusDtxEnabled
        self.redundantCodingEnabled = redundantCodingEnabled
        self.speakerDefaultOn = speakerDefaultOn
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessRequestEnabled = try container.decode(Bool.self, forKey: .accessRequestEnabled)
        self.defaultDevice = try container.decode(AudioSettingsDefaultDevice.self, forKey: .defaultDevice)
        self.hifiAudioEnabled = try container.decodeIfPresent(Bool.self, forKey: .hifiAudioEnabled)
        self.micDefaultOn = try container.decode(Bool.self, forKey: .micDefaultOn)
        self.noiseCancellation = try container.decodeIfPresent(NoiseCancellationSettingsRequest.self, forKey: .noiseCancellation)
        self.opusDtxEnabled = try container.decode(Bool.self, forKey: .opusDtxEnabled)
        self.redundantCodingEnabled = try container.decode(Bool.self, forKey: .redundantCodingEnabled)
        self.speakerDefaultOn = try container.decode(Bool.self, forKey: .speakerDefaultOn)
    }
}

extension AudioSettings: Hashable {
    public static func == (lhs: AudioSettings, rhs: AudioSettings) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.defaultDevice == rhs.defaultDevice &&
            lhs.hifiAudioEnabled == rhs.hifiAudioEnabled &&
            lhs.micDefaultOn == rhs.micDefaultOn &&
            lhs.noiseCancellation == rhs.noiseCancellation &&
            lhs.opusDtxEnabled == rhs.opusDtxEnabled &&
            lhs.redundantCodingEnabled == rhs.redundantCodingEnabled &&
            lhs.speakerDefaultOn == rhs.speakerDefaultOn
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(defaultDevice)
        hasher.combine(hifiAudioEnabled)
        hasher.combine(micDefaultOn)
        hasher.combine(noiseCancellation)
        hasher.combine(opusDtxEnabled)
        hasher.combine(redundantCodingEnabled)
        hasher.combine(speakerDefaultOn)
    }
}
