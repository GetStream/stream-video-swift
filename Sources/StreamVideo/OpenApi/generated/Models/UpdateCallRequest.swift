//
// UpdateCallRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct UpdateCallRequest: Codable, JSONEncodable, Hashable {

    /** call custom data */
    internal var custom: [String: AnyCodable]?
    internal var settingsOverride: CallSettingsRequest?

    internal init(custom: [String: AnyCodable]? = nil, settingsOverride: CallSettingsRequest? = nil) {
        self.custom = custom
        self.settingsOverride = settingsOverride
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case settingsOverride = "settings_override"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(settingsOverride, forKey: .settingsOverride)
    }
}

