//
// BackstageSettingsResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct BackstageSettingsResponse: Codable, JSONEncodable, Hashable {
    public var enabled: Bool
    public var joinAheadTimeSeconds: Int?

    public init(enabled: Bool, joinAheadTimeSeconds: Int? = nil) {
        self.enabled = enabled
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encodeIfPresent(joinAheadTimeSeconds, forKey: .joinAheadTimeSeconds)
    }
}

