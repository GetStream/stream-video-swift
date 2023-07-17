//
// AudioSettingsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct AudioSettingsRequest: Codable, JSONEncodable, Hashable {
    public enum DefaultDevice: String, Codable, CaseIterable {
        case speaker = "speaker"
        case earpiece = "earpiece"
    }
    public var accessRequestEnabled: Bool?
    public var defaultDevice: DefaultDevice
    public var micDefaultOn: Bool?
    public var opusDtxEnabled: Bool?
    public var redundantCodingEnabled: Bool?
    public var speakerDefaultOn: Bool?

    public init(accessRequestEnabled: Bool? = nil, defaultDevice: DefaultDevice, micDefaultOn: Bool? = nil, opusDtxEnabled: Bool? = nil, redundantCodingEnabled: Bool? = nil, speakerDefaultOn: Bool? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.defaultDevice = defaultDevice
        self.micDefaultOn = micDefaultOn
        self.opusDtxEnabled = opusDtxEnabled
        self.redundantCodingEnabled = redundantCodingEnabled
        self.speakerDefaultOn = speakerDefaultOn
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case defaultDevice = "default_device"
        case micDefaultOn = "mic_default_on"
        case opusDtxEnabled = "opus_dtx_enabled"
        case redundantCodingEnabled = "redundant_coding_enabled"
        case speakerDefaultOn = "speaker_default_on"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encode(defaultDevice, forKey: .defaultDevice)
        try container.encodeIfPresent(micDefaultOn, forKey: .micDefaultOn)
        try container.encodeIfPresent(opusDtxEnabled, forKey: .opusDtxEnabled)
        try container.encodeIfPresent(redundantCodingEnabled, forKey: .redundantCodingEnabled)
        try container.encodeIfPresent(speakerDefaultOn, forKey: .speakerDefaultOn)
    }
}

