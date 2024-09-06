//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ConnectUserDetailsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?
    public var id: String
    public var image: String?
    public var invisible: Bool?
    public var language: String?
    public var name: String?
    public var privacySettings: PrivacySettings?
    public var pushNotifications: PushNotificationSettingsInput?

    public init(
        custom: [String: RawJSON]? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
        language: String? = nil,
        name: String? = nil,
        privacySettings: PrivacySettings? = nil,
        pushNotifications: PushNotificationSettingsInput? = nil
    ) {
        self.custom = custom
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.name = name
        self.privacySettings = privacySettings
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case image
        case invisible
        case language
        case name
        case privacySettings = "privacy_settings"
        case pushNotifications = "push_notifications"
    }
}
