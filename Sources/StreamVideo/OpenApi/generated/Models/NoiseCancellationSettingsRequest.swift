//
// NoiseCancellationSettingsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct NoiseCancellationSettingsRequest: Codable, JSONEncodable, Hashable {
    public enum Mode: String, Codable, CaseIterable {
        case available = "available"
        case disabled = "disabled"
    }
    public var mode: Mode?

    public init(mode: Mode? = nil) {
        self.mode = mode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(mode, forKey: .mode)
    }
}

