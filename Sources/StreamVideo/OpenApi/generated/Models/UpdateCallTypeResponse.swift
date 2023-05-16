//
// UpdateCallTypeResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





internal struct UpdateCallTypeResponse: Codable, JSONEncodable, Hashable {

    internal var createdAt: Date
    internal var duration: String
    internal var grants: [String: [String]]
    internal var name: String
    internal var notificationSettings: NotificationSettings
    internal var settings: CallSettingsResponse
    internal var updatedAt: Date

    internal init(createdAt: Date, duration: String, grants: [String: [String]], name: String, notificationSettings: NotificationSettings, settings: CallSettingsResponse, updatedAt: Date) {
        self.createdAt = createdAt
        self.duration = duration
        self.grants = grants
        self.name = name
        self.notificationSettings = notificationSettings
        self.settings = settings
        self.updatedAt = updatedAt
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case duration
        case grants
        case name
        case notificationSettings = "notification_settings"
        case settings
        case updatedAt = "updated_at"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(duration, forKey: .duration)
        try container.encode(grants, forKey: .grants)
        try container.encode(name, forKey: .name)
        try container.encode(notificationSettings, forKey: .notificationSettings)
        try container.encode(settings, forKey: .settings)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

