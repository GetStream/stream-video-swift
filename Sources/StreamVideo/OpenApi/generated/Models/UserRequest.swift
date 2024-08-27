//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]? = nil
    public var id: String
    public var image: String? = nil
    public var invisible: Bool? = nil
    public var language: String? = nil
    public var name: String? = nil
    public var privacySettings: PrivacySettings? = nil
    public var pushNotifications: PushNotificationSettingsInput? = nil

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
