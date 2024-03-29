//
// HLSSettingsResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct HLSSettingsResponse: Codable, JSONEncodable, Hashable {
    public var autoOn: Bool
    public var enabled: Bool
    public var qualityTracks: [String]

    public init(autoOn: Bool, enabled: Bool, qualityTracks: [String]) {
        self.autoOn = autoOn
        self.enabled = enabled
        self.qualityTracks = qualityTracks
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoOn = "auto_on"
        case enabled
        case qualityTracks = "quality_tracks"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoOn, forKey: .autoOn)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(qualityTracks, forKey: .qualityTracks)
    }
}

