//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AudioSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum DefaultDevice: String, Sendable, Codable, CaseIterable {
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
    public var accessRequestEnabled: Bool?
    public var defaultDevice: DefaultDevice
    public var hifiAudioEnabled: Bool?
    public var micDefaultOn: Bool?
    public var noiseCancellation: NoiseCancellationSettingsRequest?
    public var opusDtxEnabled: Bool?
    public var redundantCodingEnabled: Bool?
    public var speakerDefaultOn: Bool?

    public init(
        accessRequestEnabled: Bool? = nil,
        defaultDevice: DefaultDevice,
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

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case defaultDevice = "default_device"
        case hifiAudioEnabled = "hifi_audio_enabled"
        case micDefaultOn = "mic_default_on"
        case noiseCancellation = "noise_cancellation"
        case opusDtxEnabled = "opus_dtx_enabled"
        case redundantCodingEnabled = "redundant_coding_enabled"
        case speakerDefaultOn = "speaker_default_on"
    }

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
