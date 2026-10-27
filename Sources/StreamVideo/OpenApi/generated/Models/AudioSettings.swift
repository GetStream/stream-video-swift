//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class AudioSettings: @unchecked Sendable, Decodable {
    
    public enum AudioSettingsDefaultDevice: String, Sendable, Codable, CaseIterable {
        case earpiece
        case speaker
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    public var accessRequestEnabled: Bool
    public var defaultDevice: AudioSettingsDefaultDevice
    public var hifiAudioEnabled: Bool?
    public var micDefaultOn: Bool
    public var noiseCancellation: NoiseCancellationSettingsRequest?
    public var opusDtxEnabled: Bool
    public var redundantCodingEnabled: Bool
    public var speakerDefaultOn: Bool

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
