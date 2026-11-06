//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class AudioSettingsRequestDefaultDevice: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let earpiece = AudioSettingsRequestDefaultDevice(rawValue: "earpiece")
    public static let speaker = AudioSettingsRequestDefaultDevice(rawValue: "speaker")
}

public final class AudioSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var accessRequestEnabled: Bool?
    public var defaultDevice: AudioSettingsRequestDefaultDevice
    public var hifiAudioEnabled: Bool?
    public var micDefaultOn: Bool?
    public var noiseCancellation: NoiseCancellationSettingsRequest?
    public var opusDtxEnabled: Bool?
    public var redundantCodingEnabled: Bool?
    public var speakerDefaultOn: Bool?

    public init(
        accessRequestEnabled: Bool? = nil,
        defaultDevice: AudioSettingsRequestDefaultDevice,
        hifiAudioEnabled: Bool? = nil,
        micDefaultOn: Bool? = nil,
        noiseCancellation: NoiseCancellationSettingsRequest? = nil,
        opusDtxEnabled: Bool? = nil,
        redundantCodingEnabled: Bool? = nil,
        speakerDefaultOn: Bool? = nil
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encode(defaultDevice, forKey: .defaultDevice)
        try container.encodeIfPresent(hifiAudioEnabled, forKey: .hifiAudioEnabled)
        try container.encodeIfPresent(micDefaultOn, forKey: .micDefaultOn)
        try container.encodeIfPresent(noiseCancellation, forKey: .noiseCancellation)
        try container.encodeIfPresent(opusDtxEnabled, forKey: .opusDtxEnabled)
        try container.encodeIfPresent(redundantCodingEnabled, forKey: .redundantCodingEnabled)
        try container.encodeIfPresent(speakerDefaultOn, forKey: .speakerDefaultOn)
    }
}

extension AudioSettingsRequest: Hashable {
    public static func == (lhs: AudioSettingsRequest, rhs: AudioSettingsRequest) -> Bool {
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
